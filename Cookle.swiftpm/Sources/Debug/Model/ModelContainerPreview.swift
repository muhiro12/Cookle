//
//  ModelContainerPreview.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI
import SwiftData

struct ModelContainerPreview<Content: View>: View {
    let content: (CooklePreviewStore) -> Content

    @Environment(CooklePreviewStore.self) private var store

    @State private var isReady = false

    private let previewModelContainer = try! ModelContainer(for: Recipe.self, configurations: .init(isStoredInMemoryOnly: true))

    var body: some View {
        if isReady {
            content(store)
                .modelContainer(previewModelContainer)
        } else {
            ProgressView()
                .task {
                    let context = previewModelContainer.mainContext
                    await store.prepare(context)
                    isReady = true
                }
        }
    }
}
