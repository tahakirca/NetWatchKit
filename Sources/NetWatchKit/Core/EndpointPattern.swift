//
//  EndpointPattern.swift
//  NetWatchKit
//

import Foundation

struct EndpointPattern: Codable, Identifiable, Sendable {
    var id: String { normalizedPath }
    let normalizedPath: String
    let method: String
    var hitCount: Int
    var lastAccessDate: Date
    var lastResponseBody: Data?
    var lastResponseHeaders: [String: String]?
    var lastStatusCode: Int?

    static func normalize(url: URL) -> String {
        let components = url.pathComponents
            .filter { $0 != "/" }
            .map { component -> String in
                // Replace numeric-only segments with {id}
                if !component.isEmpty, component.allSatisfy(\.isNumber) {
                    return "{id}"
                }
                // Replace UUID segments with {id}
                if UUID(uuidString: component) != nil {
                    return "{id}"
                }
                return component
            }

        return "/" + components.joined(separator: "/")
    }
}
