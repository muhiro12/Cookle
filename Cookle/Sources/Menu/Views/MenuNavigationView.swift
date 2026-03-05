//
//  MenuNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct MenuNavigationView: View {
    private enum Layout {
        static let minimumScaleFactor = CGFloat(
            Double("0.5") ?? .zero
        )
    }

    @Environment(\.isPresented)
    private var isPresented

    @AppStorage(.isDebugOn)
    private var isDebugOn

    @State private var tab: MainTab?

    private var tabs: [MainTab] {
        MainTab.allCases.filter { tab in
            switch tab {
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
            .navigationTitle(Text("Menu"))
            .toolbar {
                ToolbarItem {
                    CloseButton()
                        .hidden(!isPresented)
                }
            }
        }
        .fullScreenCover(item: $tab) { tab in
            tab.rootView
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    MenuNavigationView()
}
