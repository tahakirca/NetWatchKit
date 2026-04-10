//
//  NetWatchTriggerButton.swift
//  NetWatchKit
//

import SwiftUI

/// A button that opens the NetWatch debug panel.
/// Place this anywhere in your app to enable NetWatch access.
/// If you don't place this button, NetWatch UI won't be accessible.
public struct NetWatchTriggerButton: View {
    private let style: TriggerStyle

    public enum TriggerStyle: Sendable {
        case floating
        case inline
        case minimal
    }

    public init(style: TriggerStyle = .floating) {
        self.style = style
    }

    public var body: some View {
        #if DEBUG
        buttonContent
        #else
        if NetWatch.shared.isEnabled {
            buttonContent
        }
        #endif
    }

    private var buttonContent: some View {
        Button {
            let netWatch = NetWatch.shared
            netWatch.show()
        } label: {
            switch style {
            case .floating:
                floatingLabel
            case .inline:
                inlineLabel
            case .minimal:
                minimalLabel
            }
        }
    }

    private var floatingLabel: some View {
        Image(systemName: "antenna.radiowaves.left.and.right")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(Circle().fill(.blue))
            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
    }

    private var inlineLabel: some View {
        Label("NetWatch", systemImage: "antenna.radiowaves.left.and.right")
    }

    private var minimalLabel: some View {
        Image(systemName: "antenna.radiowaves.left.and.right")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
    }
}
