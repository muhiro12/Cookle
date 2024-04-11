//
//  PreviewData.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import Foundation
import SwiftData

struct PreviewData {
    static let modelContainer = {
        let container = try! ModelContainer(for: Recipe.self, configurations: .init(isStoredInMemoryOnly: true))
        Task { @MainActor in
            for _ in 0...20 {
                let recipe = Recipe()
                container.mainContext.insert(recipe)
                tagStore.insert(with: recipe)
                try? await Task.sleep(for: .seconds(0.2))
            }
        }
        return container
    }()

    static let tagStore = TagStore()
}
