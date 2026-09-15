import AppIntents
import CookleLibrary
import SwiftData

struct RecipeWidgetEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Recipe")
    }

    static var defaultQuery: RecipeWidgetEntityQuery {
        .init()
    }

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        .init(title: "\(name)", image: .init(systemName: "book"))
    }
}
