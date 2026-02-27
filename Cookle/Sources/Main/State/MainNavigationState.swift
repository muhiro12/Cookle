import Foundation

struct MainNavigationState {
    var selectedTab = MainTab.diary
    var pendingRoute: CookleRoute?
    var selectedDiary: Diary?
    var selectedDiaryRecipe: Recipe?
    var selectedRecipe: Recipe?
    var selectedSearchRecipe: Recipe?
    var incomingSearchQuery: String?
    var incomingSettingsSelection: SettingsContent?
    var compactSettingsSelection: SettingsContent?
    var isCompactSettingsPresented = false
}
