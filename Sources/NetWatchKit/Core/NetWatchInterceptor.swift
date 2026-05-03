//
//  NetWatchInterceptor.swift
//  NetWatchKit
//

import Foundation

final class NetWatchInterceptor: URLProtocol, @unchecked Sendable {
    private static let handledKey = "com.netwatchkit.handled.\(UUID().uuidString)"

    private lazy var session: URLSession = .init(configuration: .default, delegate: self, delegateQueue: nil)

    private let lock = NSLock()
    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()
    private var receivedResponse: HTTPURLResponse?
    private var currentRecordID: UUID?

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        guard NetWatchState.shared.isEnabled else { return false }
        guard URLProtocol.property(forKey: handledKey, in: request) == nil else { return false }
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        // URLSession converts httpBody → httpBodyStream before URLProtocol sees it.
        // Drain the stream so the body can be recorded and the forwarded request keeps it.
        if mutableRequest.httpBody == nil, let stream = mutableRequest.httpBodyStream,
           let drained = Self.drain(stream)
        {
            mutableRequest.httpBody = drained
            mutableRequest.httpBodyStream = nil
        }
        let normalizedRequest = mutableRequest as URLRequest

        // Check for mock rules
        if let rule = NetWatchState.shared.findMatchingRule(for: normalizedRequest) {
            serveMockResponse(rule: rule, request: normalizedRequest)
            return
        }

        // Record request
        let record = NetworkRecord(request: RecordedRequest(from: normalizedRequest))
        lock.withLock { currentRecordID = record.id }
        NetWatch.addRecordFromBackground(record)

        // Forward real request
        dataTask = session.dataTask(with: mutableRequest as URLRequest)
        dataTask?.resume()
    }

    private static func drain(_ stream: InputStream) -> Data? {
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 { return nil }
            if read == 0 { break }
            data.append(buffer, count: read)
        }
        return data.isEmpty ? nil : data
    }

    override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }

    // MARK: - Mock

    private func serveMockResponse(rule: MockRule, request: URLRequest) {
        let record = NetworkRecord(request: RecordedRequest(from: request))
        let recordID = record.id
        NetWatch.addRecordFromBackground(record)

        let body = rule.responseBody ?? Data()
        let statusCode = rule.statusCode
        let headers = rule.responseHeaders
        let url = request.url ?? URL(string: "about:blank")!

        let work = { [weak self] in
            guard let self else {
                // If self is deallocated, we can't deliver the response.
                // The client will get a timeout eventually.
                return
            }

            guard let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            ) else {
                let error = URLError(.badServerResponse)
                NetWatch.updateRecordFromBackground(id: recordID, response: nil, error: error.localizedDescription)
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }

            let mockResponse = RecordedResponse(
                statusCode: statusCode,
                headers: headers,
                body: body
            )

            NetWatch.updateRecordFromBackground(id: recordID, response: mockResponse, error: nil)

            self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: body)
            self.client?.urlProtocolDidFinishLoading(self)
        }

        if rule.delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + rule.delay, execute: work)
        } else {
            work()
        }
    }
}

// MARK: - URLSessionDataDelegate

extension NetWatchInterceptor: URLSessionDataDelegate {
    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        lock.withLock { receivedResponse = response as? HTTPURLResponse }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        lock.withLock { receivedData.append(data) }
        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        let (recordID, data, response) = lock.withLock {
            (currentRecordID, receivedData, receivedResponse)
        }

        guard let recordID else { return }

        if let error {
            NetWatch.updateRecordFromBackground(id: recordID, response: nil, error: error.localizedDescription)
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            let recorded = response.map { RecordedResponse(from: $0, body: data) }
            NetWatch.updateRecordFromBackground(id: recordID, response: recorded, error: nil)
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}
