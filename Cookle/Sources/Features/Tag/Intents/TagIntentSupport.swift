import SwiftData

enum TagIntentSupport {
    @MainActor
    static func ingredient(
        named value: String,
        context: ModelContext
    ) throws -> Ingredient? {
        var descriptor = FetchDescriptor<Ingredient>.ingredients(.valueIs(value))
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    @MainActor
    static func category(
        named value: String,
        context: ModelContext
    ) throws -> Category? {
        var descriptor = FetchDescriptor<Category>.categories(.valueIs(value))
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
