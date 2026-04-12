import Foundation
import MHPlatformCore

/// Stable storage keys for string values persisted in preferences.
public enum StringPreferenceKey: String, CaseIterable, Sendable, MHStringPrefDescriptorRepresentable {
    case lastOpenedRecipeID = "zxcXvb12"
    case lastLaunchedAppVersion = "s9Kp4Ld2"
    case pendingIntentDeepLinkURL = "pendingCookleIntentDeepLinkURL"

    public var preferenceDescriptor: MHStringPreferenceDescriptor {
        .init(
            storageKey: rawValue,
            defaultSelection: defaultSelection
        )
    }
}

private extension StringPreferenceKey {
    var defaultSelection: MHUserDefaultsSelection {
        switch self {
        case .lastOpenedRecipeID,
             .pendingIntentDeepLinkURL:
            .suite(UserDefaults.appGroupIdentifier)
        case .lastLaunchedAppVersion:
            .standard
        }
    }
}
