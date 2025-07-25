//
//  CookleIntents.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/8/24.
//

import SwiftData
import SwiftUI

enum CookleIntents {
    static let modelContainer = try! ModelContainer(
        for: Recipe.self,
        configurations: .init(
            cloudKitDatabase: AppStorage(.isICloudOn).wrappedValue ? .automatic : .none
        )
    )

    @MainActor static let context = modelContainer.mainContext

    static func cookleView(content: () -> some View) -> some View {
        content()
            .safeAreaPadding()
            .modelContainer(modelContainer)
    }
}
