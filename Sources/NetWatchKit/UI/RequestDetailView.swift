//
//  RequestDetailView.swift
//  NetWatchKit
//

import SwiftUI

struct RequestDetailView: View {
    let record: NetworkRecord

    @State private var showMockEditor = false

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("URL", value: record.request.url)
                LabeledContent("Method", value: record.request.method)
                if let statusCode = record.response?.statusCode {
                    LabeledContent("Status") {
                        Text("\(statusCode)")
                            .foregroundStyle(statusColor(statusCode))
                            .fontWeight(.medium)
                    }
                }
                if let duration = record.duration {
                    LabeledContent("Duration", value: Formatting.duration(duration))
                }
                if let size = record.response?.bodySize {
                    LabeledContent("Size", value: Formatting.size(size))
                }
                if let error = record.error {
                    LabeledContent("Error") {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }

            if !record.request.headers.isEmpty {
                Section("Request Headers") {
                    ForEach(record.request.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HeaderRow(key: key, value: value)
                    }
                }
            }

            if let bodyString = record.request.bodyString {
                Section("Request Body") {
                    CodeBlockView(text: Formatting.prettyJSON(bodyString))
                }
            }

            if let headers = record.response?.headers, !headers.isEmpty {
                Section("Response Headers") {
                    ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HeaderRow(key: key, value: value)
                    }
                }
            }

            if let bodyString = record.response?.bodyString {
                Section("Response Body") {
                    CodeBlockView(text: Formatting.prettyJSON(bodyString))
                }
            }

            Section {
                Button("Mock This Request") {
                    showMockEditor = true
                }

                Button("Copy as cURL") {
                    UIPasteboard.general.string = buildCURL()
                }

                if let url = URL(string: record.request.url) {
                    ShareLink(item: url)
                }
            }
        }
        .navigationTitle(shortPath)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMockEditor) {
            MockEditorView(
                urlPattern: record.request.url,
                method: record.request.method,
                existingStatusCode: record.response?.statusCode ?? 200,
                existingHeaders: record.response?.headers ?? [:],
                existingBody: record.response?.bodyString
            )
        }
    }

    private var shortPath: String {
        guard let url = URL(string: record.request.url) else { return "Detail" }
        return url.lastPathComponent.isEmpty ? url.host ?? "Detail" : url.lastPathComponent
    }

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        default: return .red
        }
    }

    private func buildCURL() -> String {
        var parts = ["curl"]
        parts.append("-X \(record.request.method)")

        for (key, value) in record.request.headers {
            parts.append("-H \(Formatting.shellEscape("\(key): \(value)"))")
        }

        if let body = record.request.bodyString {
            parts.append("-d \(Formatting.shellEscape(body))")
        }

        parts.append(Formatting.shellEscape(record.request.url))

        return parts.joined(separator: " \\\n  ")
    }
}

// MARK: - Subviews

private struct HeaderRow: View {
    let key: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(.caption.weight(.semibold))
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct CodeBlockView: View {
    let text: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
