import Observation

@MainActor
@Observable
final class MainNavigationModel {
    var selectedTab = MainTab.diary
    var selectedDiary: Diary?
    var selectedDiaryRecipe: Recipe?
    var selectedRecipe: Recipe?
    var selectedPhoto: Photo?
    var selectedSearchRecipe: Recipe?
    var selectedTagBrowser: MainTagBrowser?
    var selectedCategory: Category?
    var selectedCategoryRecipe: Recipe?
    var selectedIngredient: Ingredient?
    var selectedIngredientRecipe: Recipe?
    var incomingSearchQuery: String?
    var incomingSettingsSelection: SettingsContent?
}
