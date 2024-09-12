//
//  MainNavigationView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview

    @State private var content: MainNavigationSidebar?
    @State private var detail: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            MainNavigationSidebarView(selection: $content)
        } content: {
            if let content {
                MainNavigationContentView(content, selection: $detail)
            }
        } detail: {
            if let detail {
                MainNavigationDetailView(detail)
            }
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else {
                return
            }
            if Int.random(in: 0..<10) == .zero {
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    requestReview()
                }
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        MainNavigationView()
    }
}
