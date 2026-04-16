//
//  MenuNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import MHPlatform
import SwiftUI

struct MenuNavigationView: View {
    private enum Layout {
        static let minimumScaleFactor: CGFloat = 0.5
    }

    @Environment(\.isPresented)
    private var isPresented

    @AppStorage(\.isDebugOn)
    private var isDebugOn

    @State private var selectedTab: MainTab?

    private var tabs: [MainTab] {
        MainTab.displayedTabs(
            isRegularWidth: true,
            isDebugOn: isDebugOn
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())]) {
                    ForEach(tabs) { tab in
                        Button {
                            selectedTab = tab
                        } label: {
                            tab.label
                                .lineLimit(1)
                                .minimumScaleFactor(Layout.minimumScaleFactor)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .cookleTopLevelNavigationChrome("Menu")
            .toolbar {
                ToolbarItem {
                    CloseButton()
                        .hidden(!isPresented)
                }
            }
            .navigationDestination(isPresented: $selectedTab.isPresent()) {
                if let selectedTab {
                    selectedTab.rootView
                }
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    MenuNavigationView()
}
