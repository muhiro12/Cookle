#if DEBUG
/// Screens reachable by a capture run without simulated user interaction.
enum CookleCaptureScreen: String {
    case diary
    case diaryDetail
    case diaryDetailWithRecipe
    case recipe
    case recipeDetail
    case recipeForm
    case photo

    /// Indicates whether the capture run opens the recipe edit form over the recipe detail.
    var presentsRecipeForm: Bool {
        self == .recipeForm
    }

    /// Opens the same lunch recipe the diary lists, so the detail column is not a duplicate.
    private static func firstLunchRecipe(
        in diary: Diary?
    ) -> Recipe? {
        diary?.objects?
            .sorted { $0.order < $1.order }
            .first { $0.type == .lunch }?
            .recipe
    }

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
        case .diaryDetailWithRecipe:
            navigationModel.selectedTab = .diary
            navigationModel.selectedDiary = diaries.first
            navigationModel.selectedDiaryRecipe = Self.firstLunchRecipe(
                in: diaries.first
            ) ?? recipes.first
        case .recipe:
            navigationModel.selectedTab = .recipe
        case .recipeDetail,
             .recipeForm:
            navigationModel.selectedTab = .recipe
            navigationModel.selectedRecipe = recipes.first
        case .photo:
            navigationModel.selectedTab = .photo
        }
    }
}
#endif
