/// Canonical in-app destinations that can be represented by external URLs.
public enum CookleRoute: Equatable, Sendable {
    case home
    case diary
    case diaryDate(year: Int, month: Int, day: Int)
    case recipe
    case recipeDetail(String)
    case search(query: String?)
    case settings
    case settingsSubscription
    case settingsLicense
}
