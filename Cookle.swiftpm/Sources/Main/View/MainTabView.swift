//
//  MainTabView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var selection = MainTab.diary

    private var tabs: [MainTab] {
        MainTab.allCases.filter {
            switch $0 {
            case .diary, .recipe, .photo, .search:
                true
            case .ingredient, .category, .settings:
                horizontalSizeClass == .regular
            case .menu:
                horizontalSizeClass == .compact || !isDebugOn
            case .debug:
                horizontalSizeClass == .regular && isDebugOn
            }
        }
    }

    var body: some View {
        #if XCODE
        if #available(iOS 18.0, *) {
            TabView(selection: $selection) {
                ForEach(tabs) { tab in
                    Tab(value: tab, role: tab == .search ? .search : nil) {
                        tab.rootView
                    } label: {
                        tab.label
                    }
                }
            }
        } else {
            TabView(selection: $selection) {
                ForEach(tabs) { tab in
                    tab.rootView
                        .tag(tab)
                        .tabItem {
                            tab.label
                        }
                }
            }
        }
        #else
        TabView(selection: $selection) {
            ForEach(tabs) { tab in
                tab.rootView
                    .tag(tab)
                    .tabItem {
                        tab.label
                    }
            }
        }
        #endif
    }
}

#Preview {
    CooklePreview { _ in
        MainTabView()
    }
}
