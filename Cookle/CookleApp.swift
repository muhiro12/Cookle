//
//  CookleApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI
import SwiftData

@main
struct CookleApp: App {
    private let sharedModelContainer: ModelContainer = {
        do {
            return try .init(for: Recipe.self, configurations: .init(isStoredInMemoryOnly: true))
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
