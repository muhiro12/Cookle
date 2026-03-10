import Foundation
import MHPlatformCore

/// Stable storage keys for boolean settings persisted in app-local preferences.
public enum BoolPreferenceKey: String, MHBoolPreferenceKeyRepresentable {
    case isSubscribeOn = "qWeRty12"
    case isICloudOn = "AO9Yo1cC"
    case isDebugOn = "hd3fAy3G"
    case isDailyRecipeSuggestionNotificationOn = "m9Pq2Ls4"

    public var preferenceKey: MHBoolPreferenceKey {
        .init(
            storageKey: rawValue,
            default: false
        )
    }
}
