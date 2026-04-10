//
//  NetWatch.swift
//  NetWatchKit
//

import SwiftUI
import Observation

@MainActor
@Observable
public final class NetWatch {
    public static let shared = NetWatch()

    // MARK: - Public State

    public private(set) var isEnabled: Bool = false {
        didSet {
            NetWatchState.shared.isEnabled = isEnabled
            if isEnabled {
                registerInterceptor()
            }
        }
    }

    public var isPresented: Bool = false
    public private(set) var records: [NetworkRecord] = []

    /// Whether this instance was force-enabled for production use.
    private var isForceEnabled = false

    // MARK: - Internal

    private let storage = NetWatchStorage()
    private var isInterceptorRegistered = false

    private init() {}

    // MARK: - Public API

    /// Register NetWatchKit interceptor to a URLSessionConfiguration.
    public static func register(to configuration: URLSessionConfiguration) {
        var protocols = configuration.protocolClasses ?? []
        protocols.insert(NetWatchInterceptor.self, at: 0)
        configuration.protocolClasses = protocols
    }

    /// Start intercepting network requests.
    ///
    /// In **Debug** builds, calling `start()` is enough.
    /// In **Release** builds, you must pass `forceEnabled: true` explicitly —
    /// otherwise the call is ignored and nothing is intercepted.
    ///
    /// ```swift
    /// // Debug — just works
    /// NetWatch.shared.start()
    ///
    /// // Production — explicit opt-in
    /// NetWatch.shared.start(forceEnabled: true)
    /// ```
    public func start(forceEnabled: Bool = false) {
        #if DEBUG
        isEnabled = true
        #else
        guard forceEnabled else { return }
        isForceEnabled = true
        isEnabled = true
        #endif
    }

    /// Stop intercepting.
    public func stop() {
        isEnabled = false
    }

    /// Show the NetWatch debug panel.
    public func show() {
        guard isEnabled else { return }
        isPresented = true
    }

    /// Hide the NetWatch debug panel.
    public func hide() {
        isPresented = false
    }

    /// Clear all recorded requests from the current session.
    public func clearRecords() {
        records.removeAll()
    }

    // MARK: - Mock Rules

    public func addMockRule(_ rule: MockRule) {
        NetWatchState.shared.addMockRule(rule)
    }

    public func removeMockRule(id: UUID) {
        NetWatchState.shared.removeMockRule(id: id)
    }

    public func clearMockRules() {
        NetWatchState.shared.clearMockRules()
    }

    public var activeMockRules: [MockRule] {
        NetWatchState.shared.mockRules.filter(\.isEnabled)
    }

    public var allMockRules: [MockRule] {
        NetWatchState.shared.mockRules
    }

    // MARK: - Internal Record Management

    func addRecord(_ record: NetworkRecord) {
        records.insert(record, at: 0)
    }

    func updateRecord(id: UUID, response: RecordedResponse?, error: String?) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].response = response
        records[index].error = error
        records[index].endDate = Date()

        let record = records[index]
        let storage = self.storage
        Task.detached {
            await storage.recordRequest(record)
        }
    }

    /// Called from background threads (URLProtocol).
    nonisolated static func updateRecordFromBackground(id: UUID, response: RecordedResponse?, error: String?) {
        Task { @MainActor in
            NetWatch.shared.updateRecord(id: id, response: response, error: error)
        }
    }

    /// Called from background threads (URLProtocol).
    nonisolated static func addRecordFromBackground(_ record: NetworkRecord) {
        Task { @MainActor in
            NetWatch.shared.addRecord(record)
        }
    }

    private func registerInterceptor() {
        guard !isInterceptorRegistered else { return }
        URLProtocol.registerClass(NetWatchInterceptor.self)
        isInterceptorRegistered = true
    }
}
