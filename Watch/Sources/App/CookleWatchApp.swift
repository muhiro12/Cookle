//
//  CookleWatchApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2026/04/18.
//

import SwiftUI

@main
struct CookleWatchApp: App {
    @StateObject private var cookingSessionStore: WatchCookingSessionStore

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cookingSessionStore)
        }
    }

    init() {
        #if DEBUG
        if WatchCaptureConfiguration.isEnabled {
            _cookingSessionStore = .init(
                wrappedValue: .init(
                    previewSnapshot: WatchCaptureConfiguration.snapshot
                )
            )
            return
        }
        #endif
        _cookingSessionStore = .init(
            wrappedValue: .init()
        )
    }
}
