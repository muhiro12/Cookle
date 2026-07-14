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
