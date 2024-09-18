//
//  MainTab.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

enum MainTab {
    case diary
    case recipe
    case photo
    case ingredient
    case category
    case settings
    case debug
    case menu
    case search
}

extension MainTab {
    var label: some View {
        switch self {
        case .diary:
            Label {
                Text("Diary")
            } icon: {
                Image(systemName: "book")
            }
        case .recipe:
            Label {
                Text("Recipe")
            } icon: {
                Image(systemName: "book.pages")
            }
        case .photo:
            Label {
                Text("Photo")
            } icon: {
                Image(systemName: "photo.stack")
            }
        case .ingredient:
            Label {
                Text("Ingredient")
            } icon: {
                Image(systemName: "refrigerator")
            }
        case .category:
            Label {
                Text("Category")
            } icon: {
                Image(systemName: "frying.pan")
            }
        case .settings:
            Label {
                Text("Settings")
            } icon: {
                Image(systemName: "gear")
            }
        case .debug:
            Label {
                Text("Debug")
            } icon: {
                Image(systemName: "flask")
            }
        case .menu:
            Label {
                Text("Menu")
            } icon: {
                Image(systemName: "list.bullet")
            }
        case .search:
            Label {
                Text("Search")
            } icon: {
                Image(systemName: "magnifyingglass")
            }
        }
    }
}

extension MainTab: Identifiable {
    var id: String {
        .init(describing: self)
    }
}
