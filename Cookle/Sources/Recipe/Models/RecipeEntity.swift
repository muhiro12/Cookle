import AppIntents
import SwiftUtilities

@Observable
nonisolated final class RecipeEntity: AppEntity {
    static let defaultQuery = RecipeEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(
            name: .init("Recipe", table: "AppIntents"),
            numericFormat: LocalizedStringResource("\(placeholder: .int) Recipes", table: "AppIntents")
        )
    }

    var displayRepresentation: DisplayRepresentation {
        .init(
            title: .init(.init(name), table: "AppIntents"),
            image: .init(systemName: "book")
        )
    }

    let id: String
    let name: String
    let photos: [Data]
    let servingSize: Int
    let cookingTime: Int
    let ingredients: [String]
    let steps: [String]
    let categories: [String]
    let note: String
    let createdTimestamp: Date
    let modifiedTimestamp: Date

    init(
        id: String,
        name: String,
        photos: [Data],
        servingSize: Int,
        cookingTime: Int,
        ingredients: [String],
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
}

extension RecipeEntity: ModelBridgeable {
    typealias Model = Recipe

    convenience init?(_ model: Recipe) {
        guard let encodedID = try? model.id.base64Encoded() else {
            return nil
        }
        self.init(
            id: encodedID,
            name: model.name,
            photos: model.photos?.compactMap(\.data) ?? .empty,
            servingSize: model.servingSize,
            cookingTime: model.cookingTime,
            ingredients: model.ingredients?.map(\.value) ?? .empty,
            steps: model.steps,
            categories: model.categories?.map(\.value) ?? .empty,
            note: model.note,
            createdTimestamp: model.createdTimestamp,
            modifiedTimestamp: model.modifiedTimestamp
        )
    }
}

extension RecipeEntity: Hashable {
    static func == (lhs: RecipeEntity, rhs: RecipeEntity) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
