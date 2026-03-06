import Foundation
import MHPreferences

/// Boolean preference keys.
public enum BoolPreferenceKey: String {
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
