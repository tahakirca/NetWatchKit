//
//  NetWatchDashboard.swift
//  NetWatchKit
//

import SwiftUI

struct NetWatchDashboard: View {
    @Bindable private var netWatch = NetWatch.shared
    @State private var searchText = ""
    @State private var filterMethod: String?
    @State private var selectedTab = 0

    private var filteredRecords: [NetworkRecord] {
        var results = netWatch.records

        if !searchText.isEmpty {
            results = results.filter { $0.request.url.localizedCaseInsensitiveContains(searchText) }
        }

        if let filterMethod {
            results = results.filter { $0.request.method == filterMethod }
        }

        return results
    }

    private var methods: [String] {
        Array(Set(netWatch.records.map(\.request.method))).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    Text("Requests").tag(0)
                    Text("Mock Rules").tag(1)
                    Text("Send").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case 0:
                    requestListView
                case 1:
                    MockRulesListView()
                case 2:
                    RequestBuilderView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("NetWatch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        netWatch.isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Clear Requests", role: .destructive) {
                            netWatch.clearRecords()
                        }
                        Button("Clear Mock Rules", role: .destructive) {
                            netWatch.clearMockRules()
                        }
                        Toggle("Enabled", isOn: $netWatch.isEnabled)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private var requestListView: some View {
        VStack(spacing: 0) {
            if !methods.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: filterMethod == nil) {
                            filterMethod = nil
                        }
                        ForEach(methods, id: \.self) { method in
                            FilterChip(title: method, isSelected: filterMethod == method) {
                                filterMethod = method
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }

            List(filteredRecords) { record in
                NavigationLink(value: record.id) {
                    RequestRowView(record: record)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search URL...")
            .navigationDestination(for: UUID.self) { id in
                if let record = netWatch.records.first(where: { $0.id == id }) {
                    RequestDetailView(record: record)
                }
            }
            .overlay {
                if filteredRecords.isEmpty {
                    ContentUnavailableView(
                        "No Requests",
                        systemImage: "antenna.radiowaves.left.and.right.slash",
                        description: Text("Network requests will appear here.")
                    )
                }
            }
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
