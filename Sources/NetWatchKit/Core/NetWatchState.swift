//
//  NetWatchState.swift
//  NetWatchKit
//
//  Thread-safe shared state accessible from URLProtocol (background threads).
//  Mock rules are persisted to disk so they survive app restarts.
//

import Foundation

final class NetWatchState: @unchecked Sendable {
    static let shared = NetWatchState()

    private let lock = NSLock()
    private var _isEnabled = false
    private var _mockRules: [MockRule] = []
    private let mockRulesFileURL: URL

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = caches.appendingPathComponent("NetWatchKit", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.mockRulesFileURL = dir.appendingPathComponent("mock_rules.json")

        // Load persisted mock rules
        if let data = try? Data(contentsOf: mockRulesFileURL),
           let decoded = try? JSONDecoder().decode([MockRule].self, from: data) {
            _mockRules = decoded
        }
    }

    var isEnabled: Bool {
        get { lock.withLock { _isEnabled } }
        set { lock.withLock { _isEnabled = newValue } }
    }

    var mockRules: [MockRule] {
        get { lock.withLock { Array(_mockRules) } }
        set {
            lock.withLock { _mockRules = newValue }
            persistMockRules()
        }
    }

    func findMatchingRule(for request: URLRequest) -> MockRule? {
        lock.withLock {
            _mockRules.first { $0.matches(request) }
        }
    }

    func addMockRule(_ rule: MockRule) {
        lock.withLock { _mockRules.append(rule) }
        persistMockRules()
    }

    func removeMockRule(id: UUID) {
        lock.withLock { _mockRules.removeAll { $0.id == id } }
        persistMockRules()
    }

    func clearMockRules() {
        lock.withLock { _mockRules.removeAll() }
        persistMockRules()
    }

    // MARK: - Persistence

    private func persistMockRules() {
        let rules = lock.withLock { _mockRules }
        guard let data = try? JSONEncoder().encode(rules) else { return }
        try? data.write(to: mockRulesFileURL, options: .atomic)
    }
}
