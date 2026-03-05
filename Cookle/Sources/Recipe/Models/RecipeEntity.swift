import AppIntents
import SwiftData

@Observable
final class RecipeEntity: AppEntity, Hashable {
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
    let photos: [Data]
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

    init(
        id: String,
        name: String,
        photos: [Data],
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
        self.photos = photos
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
            photos: model.photos?.compactMap(\.data) ?? .empty,
            servingSize: model.servingSize,
            cookingTime: model.cookingTime,
            ingredients: zip(model.ingredients ?? [], model.ingredientObjects ?? []).map { ($0.value, $1.amount) },
            steps: model.steps,
            categories: model.categories?.map(\.value) ?? .empty,
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
