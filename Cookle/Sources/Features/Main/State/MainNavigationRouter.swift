import SwiftData

@MainActor
final class MainNavigationRouter {
    private let navigationModel: MainNavigationModel

    init(navigationModel: MainNavigationModel) {
        self.navigationModel = navigationModel
    }

    func apply(
        route: CookleRoute,
        context: ModelContext
    ) throws {
        let outcome = try CookleRouteExecutor.execute(
            route: route,
            context: context
        )
        apply(outcome)
    }

    func apply(
        _ outcome: CookleRouteOutcome
    ) {
        resetTransientState(for: outcome)

        switch outcome {
        case .home:
            applyHomeRoute()
        case .diary(let diary):
            applyDiaryRoute(diary: diary)
        case .recipe(let recipe):
            applyRecipeRoute(recipe: recipe)
        case .photo(let photo):
            applyPhotoRoute(photo: photo)
        case .tagCategory(let category):
            applyCategoryRoute(category: category)
        case .tagIngredient(let ingredient):
            applyIngredientRoute(ingredient: ingredient)
        case .search(let query):
            applySearchRoute(query: query)
        case .settings:
            applySettingsRoute(
                destination: nil
            )
        case .settingsSubscription:
            applySettingsRoute(
                destination: .subscription
            )
        case .settingsLicense:
            applySettingsRoute(
                destination: .license
            )
        }
    }
}

private extension MainNavigationRouter {
    func resetTransientState(
        for outcome: CookleRouteOutcome
    ) {
        if !outcome.isSettingsRoute {
            navigationModel.incomingSettingsSelection = nil
        }
        if !outcome.isTagRoute {
            navigationModel.selectedTagBrowser = nil
        }
    }

    func applyHomeRoute() {
        navigationModel.selectedTab = .diary
        navigationModel.selectedDiary = nil
        navigationModel.selectedDiaryRecipe = nil
        navigationModel.selectedRecipe = nil
        navigationModel.selectedPhoto = nil
        navigationModel.selectedSearchRecipe = nil
        navigationModel.incomingSearchQuery = nil
        navigationModel.selectedCategory = nil
        navigationModel.selectedCategoryRecipe = nil
        navigationModel.selectedIngredient = nil
        navigationModel.selectedIngredientRecipe = nil
    }

    func applyDiaryRoute(
        diary: Diary?
    ) {
        navigationModel.selectedTab = .diary
        navigationModel.selectedDiary = diary
        navigationModel.selectedDiaryRecipe = nil
    }

    func applyRecipeRoute(
        recipe: Recipe?
    ) {
        navigationModel.selectedTab = .recipe
        navigationModel.selectedRecipe = recipe
    }

    func applyPhotoRoute(
        photo: Photo?
    ) {
        navigationModel.selectedTab = .photo
        navigationModel.selectedPhoto = photo
    }

    func applyCategoryRoute(
        category: Category?
    ) {
        navigationModel.selectedTab = .search
        navigationModel.selectedSearchRecipe = nil
        navigationModel.incomingSearchQuery = nil
        navigationModel.selectedTagBrowser = .category
        navigationModel.selectedCategory = category
        navigationModel.selectedCategoryRecipe = nil
        navigationModel.selectedIngredient = nil
        navigationModel.selectedIngredientRecipe = nil
    }

    func applyIngredientRoute(
        ingredient: Ingredient?
    ) {
        navigationModel.selectedTab = .search
        navigationModel.selectedSearchRecipe = nil
        navigationModel.incomingSearchQuery = nil
        navigationModel.selectedTagBrowser = .ingredient
        navigationModel.selectedIngredient = ingredient
        navigationModel.selectedIngredientRecipe = nil
        navigationModel.selectedCategory = nil
        navigationModel.selectedCategoryRecipe = nil
    }

    func applySearchRoute(
        query: String?
    ) {
        navigationModel.selectedTab = .search
        navigationModel.selectedSearchRecipe = nil
        navigationModel.incomingSearchQuery = query
    }

    func applySettingsRoute(
        destination: SettingsContent?
    ) {
        navigationModel.selectedTab = .settings
        navigationModel.incomingSettingsSelection = destination
    }
}

private extension CookleRouteOutcome {
    var isSettingsRoute: Bool {
        switch self {
        case .settings,
             .settingsSubscription,
             .settingsLicense:
            return true
        case .home,
             .diary,
             .photo,
             .recipe,
             .tagCategory,
             .tagIngredient,
             .search:
            return false
        }
    }

    var isTagRoute: Bool {
        switch self {
        case .tagCategory,
             .tagIngredient:
            return true
        case .home,
             .diary,
             .photo,
             .recipe,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense:
            return false
        }
    }
}
