//
//  CookleShortcuts.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents

struct CookleShortcuts: AppShortcutsProvider {
    static var appShortcuts = [
        AppShortcut(
            intent: OpenCookleIntent(),
            phrases: [
                "Open \(.applicationName)"
            ],
            shortTitle: "Open Cookle",
            systemImageName: "bird"
        )
    ]
}
