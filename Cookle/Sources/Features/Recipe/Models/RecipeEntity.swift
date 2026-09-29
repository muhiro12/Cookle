import AppIntents
import CoreSpotlight
import SwiftData

@Observable
final class RecipeEntity: IndexedEntity, Hashable {
    static var defaultQuery: RecipeEntityQuery {
        .init()
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(
            name: .init("Recipe", table: "AppIntents"),
            numericFormat: LocalizedStringResource("\(placeholder: .int) Recipes", table: "AppIntents")
        )
    }

    let id: String
    let name: String
    let servingSize: Int
    let cookingTime: Int
    let ingredients: [(ingredient: String, amount: String)]
    let steps: [String]
    let categories: [String]
    let note: String
    let createdTimestamp: Date
    let modifiedTimestamp: Date

    var displayRepresentation: DisplayRepresentation {
        .init(
            title: .init(.init(name), table: "AppIntents"),
            image: .init(systemName: "book")
        )
    }

    /// Spotlight metadata beyond the display title.
    ///
    /// Ingredient names describe the recipe in search results, and ingredient
    /// and category names are offered as keywords. Steps and notes stay out
    /// of the index: they are long, personal, and add noise rather than
    /// discovery.
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        let ingredientNames = ingredients.map(\.ingredient)
        attributes.contentDescription = ingredientNames.joined(separator: ", ")
        attributes.keywords = ingredientNames + categories
        return attributes
    }

    init(
        id: String,
        name: String,
        servingSize: Int,
        cookingTime: Int,
        ingredients: [(ingredient: String, amount: String)],
        steps: [String],
        categories: [String],
        note: String,
        createdTimestamp: Date,
        modifiedTimestamp: Date
    ) {
        self.id = id
        self.name = name
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
        self.createdTimestamp = createdTimestamp
        self.modifiedTimestamp = modifiedTimestamp
    }

    static func == (lhs: RecipeEntity, rhs: RecipeEntity) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension RecipeEntity {
    convenience init?(_ model: Recipe) {
        let encodedID = RecipeStableIdentifierCodec.stableIdentifier(
            for: model
        )
        self.init(
            id: encodedID,
            name: model.name,
            servingSize: model.servingSize,
            cookingTime: model.cookingTime,
            ingredients: (model.ingredientObjects ?? []).sorted().compactMap { object in
                guard let ingredient = object.ingredient else {
                    return nil
                }
                return (ingredient.value, object.amount)
            },
            steps: model.steps,
            categories: model.categories?.map(\.value) ?? [],
            note: model.note,
            createdTimestamp: model.createdTimestamp,
            modifiedTimestamp: model.modifiedTimestamp
        )
    }
}

extension RecipeEntity {
    func model(context: ModelContext) throws -> Recipe? {
        try RecipeStableIdentifierCodec.recipe(
            from: id,
            context: context
        )
    }
}
