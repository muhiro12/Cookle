@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct ModelContainerFactoryTests {
    @Test
    func validateMigratedDataBeforeDeletingLegacyIfNeeded_passes_when_counts_match() throws {
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
        try seed(context: currentContainer.mainContext)
        try seed(context: legacyContainer.mainContext)

        try ModelContainerFactory.validateMigratedDataBeforeDeletingLegacyIfNeeded(
            currentContainer: currentContainer,
            cloudKitDatabase: .none,
            legacyURL: legacyURL,
            currentURL: currentURL
        )
    }

    @Test
    func validateMigratedDataBeforeDeletingLegacyIfNeeded_throws_when_counts_do_not_match() throws {
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
        try seed(context: legacyContainer.mainContext)

        do {
            try ModelContainerFactory.validateMigratedDataBeforeDeletingLegacyIfNeeded(
                currentContainer: currentContainer,
                cloudKitDatabase: .none,
                legacyURL: legacyURL,
                currentURL: currentURL
            )
            Issue.record("Expected migration validation mismatch error.")
        } catch let error as MigrationValidationError {
            switch error {
            case .recipeAndDiaryCountMismatch:
                break
            }
        }
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
        try seed(context: currentContainer.mainContext)

        try ModelContainerFactory.validateMigratedDataBeforeDeletingLegacyIfNeeded(
            currentContainer: currentContainer,
            cloudKitDatabase: .none,
            legacyURL: legacyURL,
            currentURL: currentURL
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
        let recipe = Recipe.create(
            context: context,
            name: "Recipe",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
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
