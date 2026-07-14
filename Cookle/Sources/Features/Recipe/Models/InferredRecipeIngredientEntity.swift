import AppIntents

@available(iOS 26.0, *)
struct InferredRecipeIngredientEntity: TransientAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Ingredient")
    }

    @Property(title: "Ingredient")
    var ingredient: String
    @Property(title: "Amount")
    var amount: String

    var displayRepresentation: DisplayRepresentation {
        let title: LocalizedStringResource = ingredient.isEmpty
            ? "Ingredient"
            : "\(ingredient)"
        guard !amount.isEmpty else {
            return .init(title: title)
        }
        return .init(
            title: title,
            subtitle: "\(amount)"
        )
    }

    init() {
        ingredient = ""
        amount = ""
    }

    init(_ inference: RecipeInferenceIngredient) {
        self.init()
        ingredient = inference.ingredient
        amount = inference.amount
    }
}
