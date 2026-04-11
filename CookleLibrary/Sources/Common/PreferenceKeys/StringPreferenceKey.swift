import MHPlatformCore

/// Stable storage keys for string values persisted in preferences.
public enum StringPreferenceKey: String, CaseIterable, MHStringPreferenceKeyRepresentable {
    case lastOpenedRecipeID = "zxcXvb12"
    case lastLaunchedAppVersion = "s9Kp4Ld2"
    case pendingIntentDeepLinkURL = "pendingCookleIntentDeepLinkURL"

    public var preferenceKey: MHStringPreferenceKey {
        .init(storageKey: rawValue)
    }
}
