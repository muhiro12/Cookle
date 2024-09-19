//
//  MainTabView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

@available(iOS 18.0, *)
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
                Tab(value: tab, role: tab == .search ? .search : nil) {
                    tab.rootView
                } label: {
                    tab.label
                }
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview {
    CooklePreview { _ in
        MainTabView()
    }
}
