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
                    Label {
                        Text("Ingredient")
                    } icon: {
                        Image(systemName: "refrigerator")
                    }
                }
                NavigationLink(value: MainTab.category) {
                    Label {
                        Text("Category")
                    } icon: {
                        Image(systemName: "frying.pan")
                    }
                }
                NavigationLink(value: MainTab.settings) {
                    Label {
                        Text("Settings")
                    } icon: {
                        Image(systemName: "gear")
                    }
                }
                if isDebugOn {
                    NavigationLink(value: MainTab.debug) {
                        Label {
                            Text("Debug")
                        } icon: {
                            Image(systemName: "flask")
                        }
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
