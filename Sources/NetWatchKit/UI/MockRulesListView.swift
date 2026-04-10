//
//  MockRulesListView.swift
//  NetWatchKit
//

import SwiftUI

struct MockRulesListView: View {
    private var netWatch = NetWatch.shared
    @State private var editingRule: MockRule?

    var body: some View {
        List {
            if netWatch.allMockRules.isEmpty {
                ContentUnavailableView(
                    "No Mock Rules",
                    systemImage: "doc.on.doc",
                    description: Text("Tap \"Mock This\" on any request to create a rule.")
                )
            } else {
                ForEach(netWatch.allMockRules) { rule in
                    MockRuleRow(rule: rule)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingRule = rule
                        }
                }
                .onDelete { indexSet in
                    let rules = netWatch.allMockRules
                    for index in indexSet {
                        guard index < rules.count else { continue }
                        netWatch.removeMockRule(id: rules[index].id)
                    }
                }
            }
        }
        .listStyle(.plain)
        .sheet(item: $editingRule) { rule in
            MockEditorView(rule: rule)
        }
    }
}

private struct MockRuleRow: View {
    let rule: MockRule

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let method = rule.method {
                    Text(method)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(methodColor(method).cornerRadius(3))
                }

                Text("\(rule.statusCode)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(rule.statusCode < 400 ? .green : .red)

                if rule.delay > 0 {
                    Label("\(String(format: "%.1f", rule.delay))s", systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Image(systemName: "pencil.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Circle()
                    .fill(rule.isEnabled ? .green : .gray)
                    .frame(width: 8, height: 8)
            }

            Text(rule.urlPattern)
                .font(.system(.subheadline, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 4)
    }

    private func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .gray
        }
    }
}
