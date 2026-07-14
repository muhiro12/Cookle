import SwiftData

enum TagIntentSupport {
    @MainActor
    static func ingredient(
        named value: String,
        context: ModelContext
    ) throws -> Ingredient? {
        let ingredients = try context.fetch(
            FetchDescriptor<Ingredient>.ingredients(.valueIs(value))
        )

        switch ingredients.count {
        case 0:
            return nil
        case 1:
            return ingredients[0]
        default:
            throw TagMutationIntentError.ambiguousIngredient(value)
        }
    }

    @MainActor
    static func category(
        named value: String,
        context: ModelContext
    ) throws -> Category? {
        let categories = try context.fetch(
            FetchDescriptor<Category>.categories(.valueIs(value))
        )

        switch categories.count {
        case 0:
            return nil
        case 1:
            return categories[0]
        default:
            throw TagMutationIntentError.ambiguousCategory(value)
        }
    }
}
