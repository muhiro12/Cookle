//
//  MainNavigationView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationView: View {
    @State private var content: MainNavigationSidebar?
    @State private var detail: Recipe?

    var body: some View {
        NavigationSplitView {
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
    }
}

#Preview {
    ModelContainerPreview { _ in
        MainNavigationView()
    }
}
