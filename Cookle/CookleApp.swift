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
            return try .init(for: Recipe.self, configurations: .init())
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let tagStore = TagStore()

    init() {
        let recipes = try? sharedModelContainer.mainContext.fetch(
            FetchDescriptor<Recipe>(
                predicate: #Predicate { _ in true }
            )
        )
        tagStore.modify(recipes ?? [])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .environment(tagStore)
    }
}
