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
            case .diary, .recipe, .photo, .menu, .search:
                true
            case .ingredient, .category, .settings:
                horizontalSizeClass == .regular
            case .debug:
                horizontalSizeClass == .regular && isDebugOn
            }
        }
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs) { tab in
                if #available(iOS 18.0, *) {
                    Tab(value: tab, role: tab == .search ? .search : nil) {
                        tab.rootView
                    } label: {
                        tab.label
                    }
                } else {
                    tab.rootView
                        .tag(tab)
                        .tabItem {
                            tab.label
                        }
                }
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        MainTabView()
    }
}
