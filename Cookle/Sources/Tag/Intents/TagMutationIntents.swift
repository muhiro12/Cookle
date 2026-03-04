import AppIntents
import SwiftData

struct RenameIngredientIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Rename Ingredient"
    }

    @Parameter(title: "Current Ingredient")
    private var currentValue: String
    @Parameter(title: "New Name")
    private var newValue: String

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var tagActionService: TagActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let ingredient = try TagIntentSupport.ingredient(
            named: currentValue,
            context: modelContainer.mainContext
        ) else {
            return .result(dialog: "Ingredient not found")
        }

        do {
            try await tagActionService.rename(
                context: modelContainer.mainContext,
                ingredient: ingredient,
                value: newValue
            )
            return .result(dialog: "Renamed ingredient")
        } catch {
            return .result(dialog: .init(stringLiteral: error.localizedDescription))
        }
    }
}

struct RenameCategoryIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Rename Category"
    }

    @Parameter(title: "Current Category")
    private var currentValue: String
    @Parameter(title: "New Name")
    private var newValue: String

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var tagActionService: TagActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let category = try TagIntentSupport.category(
            named: currentValue,
            context: modelContainer.mainContext
        ) else {
            return .result(dialog: "Category not found")
        }

        do {
            try await tagActionService.rename(
                context: modelContainer.mainContext,
                category: category,
                value: newValue
            )
            return .result(dialog: "Renamed category")
        } catch {
            return .result(dialog: .init(stringLiteral: error.localizedDescription))
        }
    }
}

struct DeleteIngredientIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Delete Ingredient"
    }

    @Parameter(title: "Ingredient")
    private var value: String

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var tagActionService: TagActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await requestDeleteConfirmation(
            dialog: .init(stringLiteral: "Delete ingredient \(value)?")
        )

        guard let ingredient = try TagIntentSupport.ingredient(
            named: value,
            context: modelContainer.mainContext
        ) else {
            return .result(dialog: "Ingredient not found")
        }

        do {
            try await tagActionService.delete(
                context: modelContainer.mainContext,
                ingredient: ingredient
            )
            return .result(dialog: "Deleted ingredient")
        } catch {
            return .result(dialog: .init(stringLiteral: error.localizedDescription))
        }
    }
}

struct DeleteCategoryIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Delete Category"
    }

    @Parameter(title: "Category")
    private var value: String

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var tagActionService: TagActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await requestDeleteConfirmation(
            dialog: .init(stringLiteral: "Delete category \(value)?")
        )

        guard let category = try TagIntentSupport.category(
            named: value,
            context: modelContainer.mainContext
        ) else {
            return .result(dialog: "Category not found")
        }

        do {
            try await tagActionService.delete(
                context: modelContainer.mainContext,
                category: category
            )
            return .result(dialog: "Deleted category")
        } catch {
            return .result(dialog: .init(stringLiteral: error.localizedDescription))
        }
    }
}

private enum TagIntentSupport {
    @MainActor
    static func ingredient(
        named value: String,
        context: ModelContext
    ) throws -> Ingredient? {
        try context.fetchFirst(.ingredients(.valueIs(value)))
    }

    @MainActor
    static func category(
        named value: String,
        context: ModelContext
    ) throws -> Category? {
        try context.fetchFirst(.categories(.valueIs(value)))
    }
}
