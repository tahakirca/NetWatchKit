//
//  Formatting.swift
//  NetWatchKit
//

import Foundation

enum Formatting {
    static func duration(_ duration: TimeInterval) -> String {
        if duration < 1 {
            return "\(Int(duration * 1000))ms"
        }
        return String(format: "%.1fs", duration)
    }

    static func size(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes)B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024)KB" }
        return String(format: "%.1fMB", Double(bytes) / 1024 / 1024)
    }

    static func prettyJSON(_ string: String) -> String {
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: pretty, encoding: .utf8) else {
            return string
        }
        return result
    }

    static func shellEscape(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
