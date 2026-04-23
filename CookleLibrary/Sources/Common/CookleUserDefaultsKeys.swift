import Foundation

/// Central catalog of app-owned `UserDefaults` storage keys.
public enum CookleUserDefaultsKeys {
    /// Keys stored in the standard app domain.
    public enum Standard: String, CaseIterable, Sendable {
        case isSubscribeOn = "qWeRty12"
        case isICloudOn = "AO9Yo1cC"
        case isDebugOn = "hd3fAy3G"
        case isDailyRecipeSuggestionNotificationOn = "m9Pq2Ls4"
        case dailyRecipeSuggestionHour = "r5Vn8Kt1"
        case dailyRecipeSuggestionMinute = "u7Bx3Jd6"
        case tipExperienceVersion = "t7Px9Nb4"
        case lastLaunchedAppVersion = "s9Kp4Ld2"
        case diaryFormSnapshot = "W6yH1nRu"
        case recipeFormSnapshot = "E8kP5sZa"
        case activeCookingSessionSnapshot = "R8pL2mQx"
        case preferenceMigrationState = "N3dR7vXc"
        case detachedObjectCleanupCompleted = "G6rK4mTp"
        case currentLogSnapshot = "J4mK7pXd"
        case previousLogSnapshot = "Q9tB3cLf"
        case recipeBrowseSortMode = "V4sP8nQm"
        case isRecipeBrowseSortAscending = "C2hL9rTa"
    }

    /// Keys stored in the shared app-group suite.
    public enum AppGroup: String, CaseIterable, Sendable {
        case lastOpenedRecipeID = "zxcXvb12"
        case pendingIntentDeepLinkURL = "L2nV8qRs"
    }

    /// All app-owned storage keys across the standard and shared domains.
    public static var allStorageKeys: [String] {
        Standard.allCases.map(\.rawValue)
            + AppGroup.allCases.map(\.rawValue)
    }
}
