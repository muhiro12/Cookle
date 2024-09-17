//
//  DiaryNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI
import SwiftUtilities

struct DiaryNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var diary: Diary?
    @State private var recipe: Recipe?

    @State private var isSettingsPresented = false
    @State private var isDebugPresented = false

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            DiaryListView(selection: $diary)
                .toolbar {
                    if horizontalSizeClass == .compact {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                isSettingsPresented = true
                            } label: {
                                Label {
                                    Text("Settings")
                                } icon: {
                                    Image(systemName: "gear")
                                }
                            }
                        }
                        if isDebugOn {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    isDebugPresented = true
                                } label: {
                                    Label {
                                        Text("Debug")
                                    } icon: {
                                        Image(systemName: "flask")
                                    }
                                }
                            }
                        }
                    }
                }
        } content: {
            if let diary {
                DiaryView(selection: $recipe)
                    .environment(diary)
            }
        } detail: {
            if let recipe {
                RecipeView()
                    .environment(recipe)
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsNavigationView()
        }
        .sheet(isPresented: $isDebugPresented) {
            DebugNavigationView()
        }
    }
}

#Preview {
    CooklePreview { _ in
        DiaryNavigationView()
    }
}
