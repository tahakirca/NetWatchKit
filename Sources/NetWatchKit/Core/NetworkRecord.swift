//
//  NetworkRecord.swift
//  NetWatchKit
//

import Foundation

public struct NetworkRecord: Identifiable, Sendable {
    public let id: UUID
    public let request: RecordedRequest
    public var response: RecordedResponse?
    public var error: String?
    public let startDate: Date
    public var endDate: Date?

    public var duration: TimeInterval? {
        guard let endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }

    init(request: RecordedRequest) {
        self.id = UUID()
        self.request = request
        self.startDate = Date()
    }
}

public struct RecordedRequest: Sendable {
    public let url: String
    public let method: String
    public let headers: [String: String]
    public let body: Data?
    public let bodyString: String?

    init(from urlRequest: URLRequest) {
        self.url = urlRequest.url?.absoluteString ?? "Unknown"
        self.method = urlRequest.httpMethod ?? "GET"
        self.headers = urlRequest.allHTTPHeaderFields ?? [:]
        self.body = urlRequest.httpBody
        self.bodyString = urlRequest.httpBody.flatMap { String(data: $0, encoding: .utf8) }
    }
}

public struct RecordedResponse: Sendable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?
    public let bodyString: String?
    public let bodySize: Int

    init(from response: HTTPURLResponse, body: Data?) {
        self.statusCode = response.statusCode
        let rawHeaders = response.allHeaderFields
        var stringHeaders: [String: String] = [:]
        for (key, value) in rawHeaders {
            stringHeaders["\(key)"] = "\(value)"
        }
        self.headers = stringHeaders
        self.body = body
        self.bodyString = body.flatMap { String(data: $0, encoding: .utf8) }
        self.bodySize = body?.count ?? 0
    }

    init(statusCode: Int, headers: [String: String], body: Data?) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.bodyString = body.flatMap { String(data: $0, encoding: .utf8) }
        self.bodySize = body?.count ?? 0
    }
}
