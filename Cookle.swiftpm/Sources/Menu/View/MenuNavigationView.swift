//
//  MenuNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct MenuNavigationView: View {
    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var selection: MainTab?

    var body: some View {
        NavigationStack {
            List(selection: $selection) {
                NavigationLink(value: MainTab.ingredient) {
                    MainTab.ingredient.label
                }
                NavigationLink(value: MainTab.category) {
                    MainTab.category.label
                }
                NavigationLink(value: MainTab.settings) {
                    MainTab.settings.label
                }
                if isDebugOn {
                    NavigationLink(value: MainTab.debug) {
                        MainTab.debug.label
                    }
                }
            }
            .navigationTitle(Text("Menu"))
        }
        .sheet(item: $selection) { selection in
            switch selection {
            case .ingredient:
                TagNavigationView<Ingredient>()
            case .category:
                TagNavigationView<Category>()
            case .settings:
                SettingsNavigationView()
            case .debug:
                DebugNavigationView()
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            MenuNavigationView()
        }
    }
}
