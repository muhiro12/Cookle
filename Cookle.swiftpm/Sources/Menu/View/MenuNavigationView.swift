//
//  MenuNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI
import SwiftUtilities

struct MenuNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.isPresented) private var isPresented

    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var tab: MainTab?

    private var tabs: [MainTab] {
        var tabs = MainTab.allCases
        tabs.removeAll {
            $0 == .debug && !isDebugOn
        }
        return tabs
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())]) {
                    ForEach(tabs) { tab in
                        Button {
                            self.tab = tab
                        } label: {
                            HStack {
                                Spacer()
                                tab.label
                                Spacer()
                            }
                            .padding()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle(Text("Menu"))
            .toolbar {
                if isPresented {
                    ToolbarItem {
                        CloseButton()
                    }
                }
            }
        }
        .fullScreenCover(item: $tab) { tab in
            tab.rootView
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
