//
//  NetWatchKitDemoApp.swift
//  NetWatchKitDemo
//

import NetWatchKit
import SwiftUI

@main
struct NetWatchKitDemoApp: App {
    init() {
        NetWatch.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .netWatch()
        }
    }
}
