//
//  NetWatchStorage.swift
//  NetWatchKit
//

import Foundation

actor NetWatchStorage {
    private let maxEndpoints = 200
    private let maxResponseSize = 512 * 1024 // 512KB
    private let expirationDays = 30

    private var endpoints: [String: EndpointPattern] = [:]
    private let cacheDirectory: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.cacheDirectory = caches.appendingPathComponent("NetWatchKit", isDirectory: true)

        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Load synchronously during init — safe because actor is not yet shared
        let file = cacheDirectory.appendingPathComponent("endpoints.json")
        if let data = try? Data(contentsOf: file),
           let decoded = try? JSONDecoder().decode([String: EndpointPattern].self, from: data) {
            endpoints = decoded
        }
    }

    // MARK: - Record

    func recordRequest(_ record: NetworkRecord) {
        guard let url = URL(string: record.request.url) else { return }

        let normalized = EndpointPattern.normalize(url: url)
        let key = "\(record.request.method) \(normalized)"

        if var existing = endpoints[key] {
            existing.hitCount += 1
            existing.lastAccessDate = Date()

            if let response = record.response {
                existing.lastStatusCode = response.statusCode
                existing.lastResponseHeaders = response.headers
                if response.bodySize <= maxResponseSize {
                    existing.lastResponseBody = response.body
                }
            }

            endpoints[key] = existing
        } else {
            var pattern = EndpointPattern(
                normalizedPath: normalized,
                method: record.request.method,
                hitCount: 1,
                lastAccessDate: Date()
            )

            if let response = record.response {
                pattern.lastStatusCode = response.statusCode
                pattern.lastResponseHeaders = response.headers
                if response.bodySize <= maxResponseSize {
                    pattern.lastResponseBody = response.body
                }
            }

            endpoints[key] = pattern
        }

        cleanup()
        saveEndpoints()
    }

    func getEndpoints() -> [EndpointPattern] {
        Array(endpoints.values).sorted { $0.hitCount > $1.hitCount }
    }

    // MARK: - Persistence

    private func saveEndpoints() {
        let file = cacheDirectory.appendingPathComponent("endpoints.json")
        guard let data = try? JSONEncoder().encode(endpoints) else { return }
        try? data.write(to: file, options: .atomic)
    }

    // MARK: - Cleanup

    private func cleanup() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -expirationDays, to: Date())
            ?? Date.distantPast

        endpoints = endpoints.filter { $0.value.lastAccessDate > cutoff }

        if endpoints.count > maxEndpoints {
            let sorted = endpoints.sorted { $0.value.hitCount < $1.value.hitCount }
            let toRemove = sorted.prefix(endpoints.count - maxEndpoints)
            for (key, _) in toRemove {
                endpoints.removeValue(forKey: key)
            }
        }
    }

    func clear() {
        endpoints.removeAll()
        saveEndpoints()
    }
}
