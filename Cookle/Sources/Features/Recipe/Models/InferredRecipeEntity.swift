import AppIntents

@available(iOS 26.0, *)
struct InferredRecipeEntity: TransientAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Inferred Recipe")
    }

    @Property(title: "Name")
    var name: String
    @Property(title: "Serving Size")
    var servingSize: Int
    @Property(title: "Cooking Time")
    var cookingTime: Int
    @Property(title: "Ingredients")
    var ingredients: [InferredRecipeIngredientEntity]
    @Property(title: "Steps")
    var steps: [String]
    @Property(title: "Categories")
    var categories: [String]
    @Property(title: "Note")
    var note: String

    var displayRepresentation: DisplayRepresentation {
        let title: LocalizedStringResource = name.isEmpty
            ? "Inferred Recipe"
            : "\(name)"
        return .init(
            title: title,
            image: .init(systemName: "book.pages")
        )
    }

    init() {
        name = ""
        servingSize = 0
        cookingTime = 0
        ingredients = []
        steps = []
        categories = []
        note = ""
    }

    init(_ inference: RecipeInferenceResult) {
        self.init()
        name = inference.name
        servingSize = inference.servingSize
        cookingTime = inference.cookingTime
        ingredients = inference.ingredients.map(InferredRecipeIngredientEntity.init)
        steps = inference.steps
        categories = inference.categories
        note = inference.note
    }
}

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
