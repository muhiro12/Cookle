//
//  CookleShortcuts.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents

struct CookleShortcuts: AppShortcutsProvider {
    static let shortcutTileColor = ShortcutTileColor.yellow

    static let appShortcuts = [
        AppShortcut(
            intent: OpenCookleIntent(),
            phrases: [
                "Open \(.applicationName)"
            ],
            shortTitle: "Open Cookle",
            systemImageName: "bird"
        ),
        AppShortcut(
            intent: ShowLastOpenedRecipeIntent(),
            phrases: [
                "Show last opened recipe in \(.applicationName)"
            ],
            shortTitle: "Show Last Opened Recipe",
            systemImageName: "clock"
        ),
        AppShortcut(
            intent: ShowRandomRecipeIntent(),
            phrases: [
                "Show random recipe in \(.applicationName)"
            ],
            shortTitle: "Show Random Recipe",
            systemImageName: "dice"
        )
    ]
}
