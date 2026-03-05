/// Validated form data used for recipe create and update flows.
public struct RecipeFormDraft: Sendable {
    public var name: String
    public var photos: [PhotoData]
    public var servingSize: Int
    public var cookingTime: Int
    public var ingredients: [RecipeFormIngredientInput]
    public var steps: [String]
    public var categories: [String]
    public var note: String

    public init(
        name: String,
        photos: [PhotoData],
        servingSize: Int,
        cookingTime: Int,
        ingredients: [RecipeFormIngredientInput],
        steps: [String],
        categories: [String],
        note: String
    ) {
        self.name = name
        self.photos = photos
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
    }
}
