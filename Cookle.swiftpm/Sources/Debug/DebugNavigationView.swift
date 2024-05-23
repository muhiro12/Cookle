//
//  DebugNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI

struct DebugNavigationView: View {
    @State private var content: DebugContent?
    @State private var detail: Int?

    var body: some View {
        NavigationSplitView {
            DebugRootView(selection: $content)
                .navigationTitle("Debug")
        } content: {
            if let content {
                DebugContentView(content, selection: $detail)
                    .navigationTitle("Content")
            }
        } detail: {
            if let detail,
               let content {
                DebugDetailView(detail, content: content)
                    .navigationTitle("Detail")
            }
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        DebugNavigationView()
    }
}
