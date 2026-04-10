//
//  MockRule.swift
//  NetWatchKit
//

import Foundation

public struct MockRule: Identifiable, Sendable, Codable {
    public let id: UUID
    public let urlPattern: String
    public let method: String?
    public var statusCode: Int
    public var responseHeaders: [String: String]
    public var responseBody: Data?
    public var delay: TimeInterval
    public var isEnabled: Bool

    public init(
        urlPattern: String,
        method: String? = nil,
        statusCode: Int = 200,
        responseHeaders: [String: String] = ["Content-Type": "application/json"],
        responseBody: Data? = nil,
        delay: TimeInterval = 0,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.urlPattern = urlPattern
        self.method = method
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.responseBody = responseBody
        self.delay = delay
        self.isEnabled = isEnabled
    }

    func matches(_ request: URLRequest) -> Bool {
        guard isEnabled else { return false }
        guard let url = request.url?.absoluteString else { return false }

        if let method, request.httpMethod ?? "GET" != method {
            return false
        }

        return urlMatchesPattern(url, pattern: urlPattern)
    }

    private func urlMatchesPattern(_ url: String, pattern: String) -> Bool {
        // Escape all regex special characters except *
        let escaped = pattern.reduce(into: "") { result, char in
            switch char {
            case ".", "(", ")", "[", "]", "{", "}", "^", "$", "|", "?", "+", "\\":
                result.append("\\")
                result.append(char)
            case "*":
                result.append(".*")
            default:
                result.append(char)
            }
        }

        guard let regex = try? NSRegularExpression(pattern: escaped, options: .caseInsensitive) else {
            // Fallback to simple contains check
            return url.localizedCaseInsensitiveContains(pattern)
        }

        return regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) != nil
    }
}
