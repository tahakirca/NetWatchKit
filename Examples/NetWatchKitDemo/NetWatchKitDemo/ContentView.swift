//
//  ContentView.swift
//  NetWatchKitDemo
//

import NetWatchKit
import SwiftUI

struct ContentView: View {
    @State private var results: [APIResult] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NetWatchTriggerButton(style: .inline)
                } header: {
                    Text("Debug")
                }

                Section {
                    RequestButton(title: "GET — Random Users", method: "GET") {
                        fetch(url: "https://randomuser.me/api/?results=3")
                    }

                    RequestButton(title: "GET — Posts", method: "GET") {
                        fetch(url: "https://jsonplaceholder.typicode.com/posts?_limit=5")
                    }

                    RequestButton(title: "GET — Comments", method: "GET") {
                        fetch(url: "https://jsonplaceholder.typicode.com/comments?postId=1")
                    }

                    RequestButton(title: "POST — Create Post", method: "POST") {
                        post(
                            url: "https://jsonplaceholder.typicode.com/posts",
                            body: ["title": "NetWatchKit Test", "body": "Hello from NetWatchKit!", "userId": "1"]
                        )
                    }

                    RequestButton(title: "PUT — Update Post", method: "PUT") {
                        put(
                            url: "https://jsonplaceholder.typicode.com/posts/1",
                            body: ["title": "Updated Title", "body": "Updated body", "userId": "1"]
                        )
                    }

                    RequestButton(title: "DELETE — Delete Post", method: "DELETE") {
                        delete(url: "https://jsonplaceholder.typicode.com/posts/1")
                    }

                    RequestButton(title: "GET — 404 Error", method: "GET") {
                        fetch(url: "https://jsonplaceholder.typicode.com/posts/99999")
                    }

                    RequestButton(title: "GET — Invalid URL (Error)", method: "GET") {
                        fetch(url: "https://thisdomaindoesnotexist12345.com/api")
                    }
                } header: {
                    Text("Tap to send requests")
                } footer: {
                    Text("Open NetWatch panel above to inspect all network traffic.")
                }

                if !results.isEmpty {
                    Section("Results") {
                        ForEach(results) { result in
                            ResultRow(result: result)
                        }
                    }
                }
            }
            .navigationTitle("NetWatchKit Demo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isLoading {
                        ProgressView()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        results.removeAll()
                    }
                    .disabled(results.isEmpty)
                }
            }
        }
    }

    // MARK: - Networking

    private func fetch(url: String) {
        guard let requestURL = URL(string: url) else { return }
        isLoading = true

        URLSession.shared.dataTask(with: requestURL) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                addResult(method: "GET", url: url, data: data, response: response, error: error)
            }
        }.resume()
    }

    private func post(url: String, body: [String: String]) {
        sendWithBody(method: "POST", url: url, body: body)
    }

    private func put(url: String, body: [String: String]) {
        sendWithBody(method: "PUT", url: url, body: body)
    }

    private func delete(url: String) {
        guard let requestURL = URL(string: url) else { return }
        isLoading = true

        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                addResult(method: "DELETE", url: url, data: data, response: response, error: error)
            }
        }.resume()
    }

    private func sendWithBody(method: String, url: String, body: [String: String]) {
        guard let requestURL = URL(string: url) else { return }
        isLoading = true

        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                addResult(method: method, url: url, data: data, response: response, error: error)
            }
        }.resume()
    }

    private func addResult(method: String, url: String, data: Data?, response: URLResponse?, error: Error?) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        let status = error != nil ? "Error" : "\(statusCode ?? 0)"
        let preview = data.flatMap { String(data: $0, encoding: .utf8) }

        let result = APIResult(
            method: method,
            url: url,
            status: status,
            isError: error != nil || (statusCode ?? 0) >= 400,
            preview: preview.map { String($0.prefix(120)) }
        )
        results.insert(result, at: 0)
    }
}

// MARK: - Subviews

private struct RequestButton: View {
    let title: String
    let method: String
    let action: () -> Void

    private var methodColor: Color {
        switch method {
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        default: return .blue
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(method)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(methodColor.cornerRadius(3))

                Text(title.components(separatedBy: " — ").last ?? title)
                    .foregroundStyle(.primary)
            }
        }
    }
}

private struct ResultRow: View {
    let result: APIResult

    private var methodColor: Color {
        switch result.method {
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        default: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.method)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(methodColor.cornerRadius(4))

                Text(result.status)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(result.isError ? .red : .green)
            }

            Text(result.url)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let preview = result.preview {
                Text(preview)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

struct APIResult: Identifiable {
    let id = UUID()
    let method: String
    let url: String
    let status: String
    let isError: Bool
    let preview: String?
}

#Preview {
    ContentView()
}
