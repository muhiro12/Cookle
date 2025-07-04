//
//  CookleShortcuts.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents

nonisolated struct CookleShortcuts: AppShortcutsProvider {
    static let shortcutTileColor = ShortcutTileColor.yellow

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenCookleIntent(),
            phrases: [
                "Open \(.applicationName)",
                "Launch \(.applicationName)",
                "Start \(.applicationName)"
            ],
            shortTitle: "Open Cookle",
            systemImageName: "bird"
        )
        AppShortcut(
            intent: ShowSearchResultIntent(),
            phrases: [
                "Search recipes in \(.applicationName)",
                "Find a recipe with \(.applicationName)",
                "Look up food using \(.applicationName)"
            ],
            shortTitle: "Show Search Result",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: ShowLastOpenedRecipeIntent(),
            phrases: [
                "Show last opened recipe in \(.applicationName)",
                "Continue my last recipe with \(.applicationName)",
                "Resume cooking in \(.applicationName)"
            ],
            shortTitle: "Show Last Opened Recipe",
            systemImageName: "clock"
        )
        AppShortcut(
            intent: ShowRandomRecipeIntent(),
            phrases: [
                "Show random recipe in \(.applicationName)",
                "Suggest something to cook with \(.applicationName)",
                "What should I make in \(.applicationName)?"
            ],
            shortTitle: "Show Random Recipe",
            systemImageName: "dice"
        )
    }
}
