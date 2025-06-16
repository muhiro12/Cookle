import AppIntents
import SwiftUtilities

@Observable
final class RecipeEntity: AppEntity {
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

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - ModelBridgeable

extension RecipeEntity: ModelBridgeable {
    typealias Model = Recipe

    convenience init?(_ model: Recipe) {
        guard let encodedID = try? model.id.base64Encoded() else {
            return nil
        }
        self.init(id: encodedID, name: model.name)
    }
}
