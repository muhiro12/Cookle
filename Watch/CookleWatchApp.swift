//
//  CookleWatchApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2026/04/18.
//

import SwiftUI

@main
struct CookleWatchApp: App {
    @StateObject private var cookingSessionStore = WatchCookingSessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cookingSessionStore)
        }
    }
}
