import MHPlatformCore

/// Applies subscription access without changing the person's saved sync choice.
public enum ICloudSyncOperations {
    /// Retains the last known access when entitlement verification is unresolved.
    public static func updateSubscriptionAccess(
        isActive: Bool?,
        store: MHPreferenceStore = .init()
    ) {
        guard let isActive else {
            return
        }
        store.set(isActive, for: \.isSubscribeOn)
    }

    /// Defers enabling sync during an edit while applying loss of access immediately.
    public static func settingToApply(
        isSyncAlreadyRequested: Bool,
        isEditing: Bool,
        store: MHPreferenceStore = .init()
    ) -> Bool {
        store.bool(for: \.isSubscribeOn)
            && store.bool(for: \.isICloudOn)
            && (isSyncAlreadyRequested || !isEditing)
    }
}
