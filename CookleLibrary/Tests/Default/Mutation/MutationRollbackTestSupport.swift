@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Shared fixtures for the rollback persistence suites.
///
/// The suites are split by domain to keep each file readable, so the disk-store
/// scaffolding they both need lives here rather than in either one.
@MainActor
protocol MutationRollbackTestSupport {}

extension MutationRollbackTestSupport {
    // A protocol extension cannot store a property, so this is computed.
    static var day: Date {
        Date(
            timeIntervalSinceReferenceDate: MutationRollbackValues.dayReference
        )
    }

    func withDiskStore(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        try body(directory.appendingPathComponent("store.sqlite"))
    }

    func makeContext(at url: URL) throws -> ModelContext {
        let container = try ModelContainerFactory.makeModelContainer(
            url: url,
            cloudKitDatabase: .none
        )
        let context = ModelContext(container)
        // Autosave would defeat the point: rollback can only prove anything
        // while the mutation is still uncommitted.
        context.autosaveEnabled = false
        return context
    }

    func seedPhotographedRecipe(context: ModelContext) throws {
        let photo = try Photo.create(
            context: context,
            photoData: .init(data: Data("photo".utf8), source: .photosPicker)
        )
        let photoObject = PhotoObject.restore(
            context: context,
            photo: photo,
            order: .zero,
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        _ = Recipe.create(
            context: context,
            content: .init(
                name: "Curry",
                photos: [photoObject],
                servingSize: MutationRollbackValues.servingSize,
                cookingTime: MutationRollbackValues.cookingTimeMinutes,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
    }

    func makePhotoDraft(
        photoNames: [String],
        name: String = "Curry"
    ) throws -> RecipeFormDraft {
        try RecipeFormOperations.makeDraft(
            input: .init(
                name: name,
                photos: photoNames.map { name in
                    .init(data: Data(name.utf8), source: .photosPicker)
                },
                servingSize: "2",
                cookingTime: "30",
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
    }

    func makeCurryDraft() throws -> RecipeFormDraft {
        try RecipeFormOperations.makeDraft(
            input: .init(
                name: "Curry",
                photos: [],
                servingSize: "2",
                cookingTime: "30",
                ingredients: [
                    .init(ingredient: "Onion", amount: "1"),
                    .init(ingredient: "Rice", amount: "2 cups")
                ],
                steps: ["Chop.", "Simmer."],
                categories: ["Dinner"],
                note: "Weeknight"
            )
        )
    }

    func makeContent(name: String, note: String = "") -> RecipeContent {
        .init(
            name: name,
            photos: [],
            servingSize: MutationRollbackValues.servingSize,
            cookingTime: MutationRollbackValues.cookingTimeMinutes,
            ingredients: [],
            steps: [],
            categories: [],
            note: note
        )
    }

    func makeRecipe(context: ModelContext, name: String) -> Recipe {
        Recipe.create(
            context: context,
            content: makeContent(name: name)
        )
    }
}
