//
//  CookleIntents.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents
import SwiftData
import SwiftUI

@MainActor
public enum CookleIntents {}

public extension CookleIntents {
    static func performOpenCookle() async throws -> some IntentResult {
        .result()
    }

    static func performShowRandomRecipe() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        var descriptor = FetchDescriptor.recipes(.all)

        let count = try context.fetchCount(descriptor)
        let offset = Int.random(in: 0..<count)

        descriptor.fetchOffset = offset
        descriptor.fetchLimit = 1

        guard let recipe = try context.fetch(descriptor).first else {
            return .result(dialog: "Not Found")
        }

        return .result(dialog: .init(stringLiteral: recipe.name)) {
            cookleView {
                VStack(alignment: .leading) {
                    ForEach(recipe.ingredientObjects.orEmpty.sorted { $0.order < $1.order }, id: \.self) { ingredientObject in
                        HStack {
                            Text(ingredientObject.ingredient?.value ?? .empty)
                            Spacer()
                            Text(ingredientObject.amount)
                        }
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Private

private extension CookleIntents {
    static let modelContainer = try! ModelContainer(
        for: Recipe.self,
        configurations: .init(
            cloudKitDatabase: AppStorage(.isICloudOn).wrappedValue ? .automatic : .none
        )
    )

    static let context = modelContainer.mainContext

    static func cookleView(content: () -> some View) -> some View {
        content()
            .safeAreaPadding()
            .modelContainer(modelContainer)
            .cookleEnvironment(
                googleMobileAds: { _ in EmptyView() },
                licenseList: { EmptyView() },
                storeKit: { EmptyView() }
            )
    }
}
