//
//  OldMainTabView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct OldMainTabView: View {
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
                tab.rootView
                    .tag(tab)
                    .tabItem {
                        tab.label
                    }
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        OldMainTabView()
    }
}
