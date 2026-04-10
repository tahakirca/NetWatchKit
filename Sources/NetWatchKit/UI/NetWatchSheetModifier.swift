//
//  NetWatchSheetModifier.swift
//  NetWatchKit
//

import SwiftUI

/// Attach this modifier to your root view to enable the NetWatch sheet presentation.
public struct NetWatchSheetModifier: ViewModifier {
    @Bindable private var netWatch = NetWatch.shared

    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: $netWatch.isPresented) {
                NetWatchDashboard()
            }
    }
}

public extension View {
    /// Enables NetWatch sheet presentation on this view.
    /// Attach to your root view (e.g. in your App's WindowGroup).
    func netWatch() -> some View {
        modifier(NetWatchSheetModifier())
    }
}
