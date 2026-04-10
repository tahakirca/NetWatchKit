//
//  RequestRowView.swift
//  NetWatchKit
//

import SwiftUI

struct RequestRowView: View {
    let record: NetworkRecord

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(record.request.method)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(methodColor.cornerRadius(4))

                    if let statusCode = record.response?.statusCode {
                        Text("\(statusCode)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(statusColor)
                    }
                }

                Text(shortURL)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    if let duration = record.duration {
                        Label(Formatting.duration(duration), systemImage: "clock")
                    } else if record.error == nil {
                        Label("Loading...", systemImage: "clock")
                    }

                    if let size = record.response?.bodySize {
                        Label(Formatting.size(size), systemImage: "doc")
                    }

                    Text(record.startDate.formatted(.dateTime.hour().minute().second()))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var shortURL: String {
        guard let url = URL(string: record.request.url) else { return record.request.url }
        let path = url.path
        let query = url.query.map { "?\($0)" } ?? ""
        return path + query
    }

    private var statusColor: Color {
        if record.error != nil { return .red }
        guard let code = record.response?.statusCode else { return .orange }
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        default: return .red
        }
    }

    private var methodColor: Color {
        switch record.request.method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .gray
        }
    }
}
