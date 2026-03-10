import Foundation
import MHPlatformCore

/// Stable storage keys for string values persisted in app-local preferences.
public enum StringPreferenceKey: String, MHStringPreferenceKeyRepresentable {
    case lastOpenedRecipeID = "zxcXvb12"
    case lastLaunchedAppVersion = "s9Kp4Ld2"

    public var preferenceKey: MHStringPreferenceKey {
        .init(storageKey: rawValue)
    }
}
