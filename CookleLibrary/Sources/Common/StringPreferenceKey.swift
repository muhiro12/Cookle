import Foundation
import MHPreferences

/// String preference keys.
public enum StringPreferenceKey: String {
    case lastOpenedRecipeID = "zxcXvb12"
    case lastLaunchedAppVersion = "s9Kp4Ld2"

    public var preferenceKey: MHStringPreferenceKey {
        .init(storageKey: rawValue)
    }
}
