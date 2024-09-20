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
        MainTab.allCases.filter {
            switch $0 {
            case .debug:
                isDebugOn
            default:
                true
            }
        }
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
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
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
        MenuNavigationView()
    }
}
