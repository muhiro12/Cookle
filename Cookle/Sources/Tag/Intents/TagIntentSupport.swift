import SwiftData

enum TagIntentSupport {
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
