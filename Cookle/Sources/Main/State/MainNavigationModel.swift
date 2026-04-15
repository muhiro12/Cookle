import Observation

@MainActor
@Observable
final class MainNavigationModel {
    var selectedTab = MainTab.diary
    var selectedDiary: Diary?
    var selectedDiaryRecipe: Recipe?
    var selectedRecipe: Recipe?
    var selectedSearchRecipe: Recipe?
    var incomingSearchQuery: String?
    var incomingSettingsSelection: SettingsContent?
}
