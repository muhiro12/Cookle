import FoundationModels

@available(iOS 26.0, *)
@Generable
struct InferredRecipeFormIngredient {
    var ingredient: String
    var amount: String
}

@available(iOS 26.0, *)
@Generable
struct InferredRecipeForm {
    var name: String
    var servingSize: Int
    var cookingTime: Int
    var ingredients: [InferredRecipeFormIngredient]
    var steps: [String]
    var categories: [String]
    var note: String
}
