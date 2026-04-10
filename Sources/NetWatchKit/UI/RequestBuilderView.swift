//
//  RequestBuilderView.swift
//  NetWatchKit
//

import SwiftUI

struct RequestBuilderView: View {
    @State private var url = ""
    @State private var method = "GET"
    @State private var headers: [HeaderEntry] = [HeaderEntry()]
    @State private var bodyText = ""
    @State private var isLoading = false
    @State private var result: BuilderResult?
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]

    private enum Field: Hashable {
        case url
        case headerKey(UUID)
        case headerValue(UUID)
        case body
    }

    private var hasBody: Bool {
        method != "GET" && method != "HEAD"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Method + URL
                VStack(spacing: 12) {
                    // Method selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(methods, id: \.self) { m in
                                Button {
                                    withAnimation(.snappy(duration: 0.2)) { method = m }
                                } label: {
                                    Text(m)
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(method == m ? methodColor(m) : Color(.tertiarySystemFill))
                                        .foregroundStyle(method == m ? .white : .secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // URL field
                    HStack(spacing: 0) {
                        Image(systemName: "link")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 36)

                        TextField("https://api.example.com/users", text: $url, prompt: Text("https://api.example.com/users").foregroundStyle(.tertiary))
                            .font(.system(.subheadline, design: .monospaced))
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .url)
                    }
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }

                // MARK: - Headers
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Headers", systemImage: "list.bullet.rectangle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                headers.append(HeaderEntry())
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal)

                    VStack(spacing: 6) {
                        ForEach($headers) { $header in
                            HStack(spacing: 8) {
                                TextField("Key", text: $header.key)
                                    .font(.system(.caption, design: .monospaced))
                                    .focused($focusedField, equals: .headerKey(header.id))

                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 1, height: 20)

                                TextField("Value", text: $header.value)
                                    .font(.system(.caption, design: .monospaced))
                                    .focused($focusedField, equals: .headerValue(header.id))

                                if headers.count > 1 {
                                    Button {
                                        withAnimation(.snappy(duration: 0.2)) {
                                            headers.removeAll { $0.id == header.id }
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                }

                // MARK: - Body
                if hasBody {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Body", systemImage: "doc.text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        TextEditor(text: $bodyText)
                            .font(.system(.caption, design: .monospaced))
                            .focused($focusedField, equals: .body)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                            .overlay(alignment: .topLeading) {
                                if bodyText.isEmpty {
                                    Text("{ \"key\": \"value\" }")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.quaternary)
                                        .padding(.leading, 26)
                                        .padding(.top, 18)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                }

                // MARK: - Error
                if let errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // MARK: - Send Button
                Button {
                    focusedField = nil
                    sendRequest()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Send")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(url.isEmpty ? Color.gray : methodColor(method))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(url.isEmpty || isLoading)
                .padding(.horizontal)

                // MARK: - Response
                if let result {
                    VStack(spacing: 0) {
                        // Status bar
                        HStack {
                            Text("\(result.statusCode)")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(result.statusCode >= 400 || result.statusCode == 0 ? .red : .green)

                            Text(HTTPURLResponse.localizedString(forStatusCode: result.statusCode).capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            HStack(spacing: 12) {
                                Label(result.duration, systemImage: "clock")
                                Label(result.size, systemImage: "doc")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.horizontal)

                        // Response Headers
                        if !result.headers.isEmpty {
                            DisclosureGroup {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(result.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        HStack(alignment: .top, spacing: 4) {
                                            Text(key)
                                                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                                                .foregroundStyle(.blue)
                                            Text(value)
                                                .font(.system(.caption2, design: .monospaced))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            } label: {
                                Text("Response Headers (\(result.headers.count))")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        // Response Body
                        if let body = result.body, !body.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Body")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Button {
                                        UIPasteboard.general.string = body
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                            .font(.caption2)
                                    }
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    Text(body)
                                        .font(.system(.caption2, design: .monospaced))
                                        .textSelection(.enabled)
                                        .padding(10)
                                }
                                .frame(maxHeight: 300)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Send

    private func sendRequest() {
        withAnimation(.snappy(duration: 0.2)) { errorMessage = nil }

        guard let requestURL = URL(string: url) else {
            withAnimation(.snappy(duration: 0.2)) {
                errorMessage = "Invalid URL. Include https:// or http://"
            }
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method

        for header in headers where !header.key.isEmpty {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        if hasBody, !bodyText.isEmpty {
            request.httpBody = bodyText.data(using: .utf8)
        }

        isLoading = true
        withAnimation(.snappy(duration: 0.2)) { result = nil }
        let start = Date()

        URLSession.shared.dataTask(with: request) { data, response, error in
            let duration = Date().timeIntervalSince(start)

            DispatchQueue.main.async {
                isLoading = false

                if let error {
                    withAnimation(.snappy(duration: 0.3)) {
                        result = BuilderResult(
                            statusCode: 0,
                            headers: [:],
                            body: error.localizedDescription,
                            duration: Formatting.duration(duration),
                            size: "0B"
                        )
                    }
                    return
                }

                let httpResponse = response as? HTTPURLResponse
                let bodyString = data.flatMap { String(data: $0, encoding: .utf8) }

                let rawHeaders = httpResponse?.allHeaderFields ?? [:]
                var stringHeaders: [String: String] = [:]
                for (key, value) in rawHeaders {
                    stringHeaders["\(key)"] = "\(value)"
                }

                withAnimation(.snappy(duration: 0.3)) {
                    result = BuilderResult(
                        statusCode: httpResponse?.statusCode ?? 0,
                        headers: stringHeaders,
                        body: bodyString.map { Formatting.prettyJSON($0) },
                        duration: Formatting.duration(duration),
                        size: Formatting.size(data?.count ?? 0)
                    )
                }
            }
        }.resume()
    }

    private func methodColor(_ m: String) -> Color {
        switch m {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "PATCH": return .purple
        case "DELETE": return .red
        default: return .gray
        }
    }
}

// MARK: - Models

private struct HeaderEntry: Identifiable {
    let id = UUID()
    var key = ""
    var value = ""
}

private struct BuilderResult {
    let statusCode: Int
    let headers: [String: String]
    let body: String?
    let duration: String
    let size: String
}
