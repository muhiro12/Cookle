import AppIntents

struct OpenRecipesIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Open Recipes"
    }

    static var openAppWhenRun: Bool {
        true
    }

    @MainActor
    func perform() -> some IntentResult {
        CookleRouteIntentSupport.open(.recipe)
        return .result()
    }
}

struct OpenRecipeIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Open Recipe"
    }

    static var openAppWhenRun: Bool {
        true
    }

    @Parameter(title: "Recipe")
    private var recipe: RecipeEntity

    @MainActor
    func perform() -> some IntentResult {
        CookleRouteIntentSupport.open(
            .recipeDetail(recipe.id)
        )
        return .result()
    }
}
