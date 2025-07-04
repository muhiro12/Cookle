//
//  ModelContainerPreview.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftData
import SwiftUI

struct ModelContainerPreview<Content: View>: View {
    let content: (CooklePreviewStore) -> Content

    @Environment(CooklePreviewStore.self) private var preview

    @State private var isReady = false

    private let previewModelContainer = try! ModelContainer(for: Recipe.self, configurations: .init(isStoredInMemoryOnly: true))

    var body: some View {
        if isReady {
            content(preview)
                .modelContainer(previewModelContainer)
        } else {
            ProgressView()
                .task {
                    await preview.prepare(previewModelContainer.mainContext)
                    isReady = true
                }
        }
    }
}
