/// Editable persisted content for a recipe aggregate.
public struct RecipeContent {
    /// Display name of the recipe.
    public var name: String
    /// Ordered photo objects attached to the recipe.
    public var photos: [PhotoObject]
    /// Number of servings produced by the recipe.
    public var servingSize: Int
    /// Cooking time in minutes.
    public var cookingTime: Int
    /// Ordered ingredient objects attached to the recipe.
    public var ingredients: [IngredientObject]
    /// Ordered preparation steps.
    public var steps: [String]
    /// Categories assigned to the recipe.
    public var categories: [Category]
    /// Freeform recipe note.
    public var note: String

    /// Creates editable persisted recipe content.
    public init(
        name: String,
        photos: [PhotoObject] = [],
        servingSize: Int = .zero,
        cookingTime: Int = .zero,
        ingredients: [IngredientObject] = [],
        steps: [String] = [],
        categories: [Category] = [],
        note: String = ""
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
