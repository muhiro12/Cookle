#if DEBUG
/// Screens reachable by a capture run without simulated user interaction.
enum CookleCaptureScreen: String {
    case diary
    case diaryDetail
    case recipe
    case recipeDetail
    case photo

    @MainActor
    func apply(
        to navigationModel: MainNavigationModel,
        recipes: [Recipe],
        diaries: [Diary]
    ) {
        switch self {
        case .diary:
            navigationModel.selectedTab = .diary
        case .diaryDetail:
            navigationModel.selectedTab = .diary
            navigationModel.selectedDiary = diaries.first
            navigationModel.selectedDiaryRecipe = recipes.first
        case .recipe:
            navigationModel.selectedTab = .recipe
        case .recipeDetail:
            navigationModel.selectedTab = .recipe
            navigationModel.selectedRecipe = recipes.first
        case .photo:
            navigationModel.selectedTab = .photo
        }
    }
}
#endif
