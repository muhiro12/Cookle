@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

struct ModelContainerFactoryTests {
    @Test
    @MainActor
    func validateMigratedDataBeforeDeletingLegacyIfNeeded_passes_when_relocated_store_opens() throws {
        let sandbox = try makeSandboxDirectory()
        defer {
            try? FileManager.default.removeItem(at: sandbox)
        }
        let currentURL = sandbox.appendingPathComponent("current.sqlite")
        let legacyURL = sandbox.appendingPathComponent("legacy.sqlite")

        let currentContainer = try ModelContainerFactory.makeModelContainer(
            url: currentURL,
            cloudKitDatabase: .none
        )
        let legacyContainer = try ModelContainerFactory.makeModelContainer(
            url: legacyURL,
            cloudKitDatabase: .none
        )
        try seed(context: .init(currentContainer))
        try seed(context: .init(legacyContainer))

        try ModelContainerFactory.validateMigratedDataBeforeDeletingLegacyIfNeeded(
            currentStoreURL: currentURL,
            cloudKitDatabase: .none,
            legacyURL: legacyURL
        )

        let reopenedContainer = try ModelContainerFactory.makeModelContainer(
            url: currentURL,
            cloudKitDatabase: .none
        )
        let recipes = try reopenedContainer.mainContext.fetch(
            FetchDescriptor<Recipe>()
        )
        #expect(recipes.count == 1)
    }

    @Test
    func validateMigratedDataBeforeDeletingLegacyIfNeeded_skips_when_legacy_is_missing() throws {
        let sandbox = try makeSandboxDirectory()
        defer {
            try? FileManager.default.removeItem(at: sandbox)
        }
        let currentURL = sandbox.appendingPathComponent("current.sqlite")
        let legacyURL = sandbox.appendingPathComponent("missing-legacy.sqlite")

        let currentContainer = try ModelContainerFactory.makeModelContainer(
            url: currentURL,
            cloudKitDatabase: .none
        )
        try seed(context: .init(currentContainer))

        try ModelContainerFactory.validateMigratedDataBeforeDeletingLegacyIfNeeded(
            currentStoreURL: currentURL,
            cloudKitDatabase: .none,
            legacyURL: legacyURL
        )
    }
}

private extension ModelContainerFactoryTests {
    func makeSandboxDirectory() throws -> URL {
        let sandbox = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: sandbox,
            withIntermediateDirectories: true
        )
        return sandbox
    }

    func seed(context: ModelContext) throws {
        let cookingTime = Int("10") ?? .zero
        let recipe = Recipe.create(
            context: context,
            name: "Recipe",
            photos: [],
            servingSize: 1,
            cookingTime: cookingTime,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        _ = Diary.create(
            context: context,
            date: .now,
            objects: [
                .create(
                    context: context,
                    recipe: recipe,
                    type: .breakfast,
                    order: 1
                )
            ],
            note: ""
        )
        try context.save()
    }
}
