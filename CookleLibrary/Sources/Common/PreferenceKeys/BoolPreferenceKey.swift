import MHPlatformCore

/// Stable storage keys for boolean settings persisted in preferences.
public enum BoolPreferenceKey: String, CaseIterable, Sendable, MHBoolPrefDescriptorRepresentable {
    case isSubscribeOn = "qWeRty12"
    case isICloudOn = "AO9Yo1cC"
    case isDebugOn = "hd3fAy3G"
    case isDailyRecipeSuggestionNotificationOn = "m9Pq2Ls4"

    public var preferenceDescriptor: MHBoolPreferenceDescriptor {
        .init(
            storageKey: rawValue,
            defaultSelection: .standard,
            default: false
        )
    }
}
