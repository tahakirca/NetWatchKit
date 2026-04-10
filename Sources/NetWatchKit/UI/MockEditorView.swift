//
//  MockEditorView.swift
//  NetWatchKit
//

import SwiftUI

struct MockEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let urlPattern: String
    let method: String
    /// If editing an existing rule, this is its ID. On save we remove the old and insert updated.
    let existingRuleID: UUID?

    @State private var statusCode: String
    @State private var responseBody: String
    @State private var delay: String
    @State private var isEnabled: Bool

    private let statusCodes = [
        (200, "OK"), (201, "Created"), (204, "No Content"),
        (301, "Moved"), (304, "Not Modified"),
        (400, "Bad Request"), (401, "Unauthorized"), (403, "Forbidden"),
        (404, "Not Found"), (422, "Unprocessable"),
        (500, "Server Error"), (502, "Bad Gateway"), (503, "Unavailable"),
    ]

    /// Create a new mock rule from a recorded request.
    init(
        urlPattern: String,
        method: String,
        existingStatusCode: Int,
        existingHeaders: [String: String],
        existingBody: String?
    ) {
        self.urlPattern = urlPattern
        self.method = method
        self.existingRuleID = nil
        self._statusCode = State(initialValue: "\(existingStatusCode)")
        self._responseBody = State(initialValue: Formatting.prettyJSON(existingBody ?? ""))
        self._delay = State(initialValue: "0")
        self._isEnabled = State(initialValue: true)
    }

    /// Edit an existing mock rule.
    init(rule: MockRule) {
        self.urlPattern = rule.urlPattern
        self.method = rule.method ?? "ANY"
        self.existingRuleID = rule.id
        self._statusCode = State(initialValue: "\(rule.statusCode)")
        self._responseBody = State(initialValue: rule.responseBody.flatMap({ String(data: $0, encoding: .utf8) }).map { Formatting.prettyJSON($0) } ?? "")
        self._delay = State(initialValue: rule.delay == 0 ? "0" : "\(rule.delay)")
        self._isEnabled = State(initialValue: rule.isEnabled)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Endpoint info
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Text(method)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(methodColor.cornerRadius(6))

                            Text(shortURL)
                                .font(.system(.subheadline, design: .monospaced))
                                .lineLimit(2)
                                .foregroundStyle(.primary)

                            Spacer()
                        }

                        if shortURL != urlPattern {
                            Text(urlPattern)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // MARK: - Status Code
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Status Code")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(statusCodes, id: \.0) { code, label in
                                    Button {
                                        withAnimation(.snappy(duration: 0.15)) {
                                            statusCode = "\(code)"
                                        }
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text("\(code)")
                                                .font(.subheadline.weight(.bold))
                                            Text(label)
                                                .font(.caption2)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(
                                            statusCode == "\(code)"
                                                ? statusColor(code)
                                                : Color(.tertiarySystemFill)
                                        )
                                        .foregroundStyle(statusCode == "\(code)" ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Custom code field
                        HStack(spacing: 8) {
                            Text("Custom:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("200", text: $statusCode)
                                .font(.system(.subheadline, design: .monospaced).weight(.medium))
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal)
                    }

                    // MARK: - Delay
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Delay")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(delayLabel)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["0", "0.5", "1", "2", "3", "5", "10", "30"], id: \.self) { value in
                                    Button {
                                        withAnimation(.snappy(duration: 0.15)) {
                                            delay = value
                                        }
                                    } label: {
                                        Text(value == "0" ? "None" : "\(value)s")
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                delay == value
                                                    ? Color.orange
                                                    : Color(.tertiarySystemFill)
                                            )
                                            .foregroundStyle(delay == value ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // MARK: - Enabled Toggle
                    if existingRuleID != nil {
                        HStack {
                            Text("Enabled")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Toggle("", isOn: $isEnabled)
                                .labelsHidden()
                        }
                        .padding(.horizontal)
                    }

                    // MARK: - Response Body
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Response Body")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                responseBody = Formatting.prettyJSON(responseBody)
                            } label: {
                                Label("Format", systemImage: "text.alignleft")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal)

                        TextEditor(text: $responseBody)
                            .font(.system(.caption, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(alignment: .topLeading) {
                                if responseBody.isEmpty {
                                    Text("{ \"key\": \"value\" }")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.quaternary)
                                        .padding(.leading, 14)
                                        .padding(.top, 18)
                                        .allowsHitTesting(false)
                                }
                            }
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existingRuleID != nil ? "Edit Rule" : "Mock Response")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingRuleID != nil ? "Update" : "Save") {
                        saveMockRule()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helpers

    private var shortURL: String {
        guard let url = URL(string: urlPattern) else { return urlPattern }
        let path = url.path
        let query = url.query.map { "?\($0)" } ?? ""
        return path + query
    }

    private var delayLabel: String {
        guard let d = Double(delay), d > 0 else { return "Instant" }
        if d < 1 { return "\(Int(d * 1000))ms delay" }
        return "\(delay)s delay"
    }

    private var methodColor: Color {
        switch method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .gray
        }
    }

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        default: return .red
        }
    }

    private func saveMockRule() {
        // Remove old rule if editing
        if let existingRuleID {
            NetWatch.shared.removeMockRule(id: existingRuleID)
        }

        let rule = MockRule(
            urlPattern: urlPattern,
            method: method == "ANY" ? nil : method,
            statusCode: Int(statusCode) ?? 200,
            responseBody: responseBody.data(using: .utf8),
            delay: Double(delay) ?? 0,
            isEnabled: isEnabled
        )
        NetWatch.shared.addMockRule(rule)
    }
}
