//
//  CookleShortcuts.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents

struct CookleShortcuts: AppShortcutsProvider {
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
            intent: OpenRecipesIntent(),
            phrases: [
                "Open recipes in \(.applicationName)",
                "Show my recipes in \(.applicationName)",
                "Browse recipes with \(.applicationName)"
            ],
            shortTitle: "Open Recipes",
            systemImageName: "list.bullet"
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
        AppShortcut(
            intent: ShowTodayDiaryIntent(),
            phrases: [
                "Show today's diary in \(.applicationName)",
                "Open today's meals in \(.applicationName)",
                "Check today's cooking log in \(.applicationName)"
            ],
            shortTitle: "Show Today's Diary",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: OpenSettingsIntent(),
            phrases: [
                "Open settings in \(.applicationName)",
                "Show settings in \(.applicationName)",
                "Go to settings in \(.applicationName)"
            ],
            shortTitle: "Open Settings",
            systemImageName: "gearshape"
        )
    }
}
