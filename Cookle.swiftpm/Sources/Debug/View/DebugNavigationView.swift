//
//  DebugNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI
import SwiftUtilities

struct DebugNavigationView: View {
    @Environment(\.isPresented) private var isPresented

    @State private var content: DebugContent?
    @State private var detail: Int?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            DebugNavigationSidebarView(selection: $content)
                .toolbar {
                    if isPresented {
                        CloseButton()
                    }
                }
        } content: {
            if let content {
                DebugNavigationContentView(content, selection: $detail)
            }
        } detail: {
            if let detail,
               let content {
                DebugNavigationDetailView(detail, content: content)
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        DebugNavigationView()
    }
}
