import MHPlatformCore

/// Applies subscription access without changing the person's saved sync choice.
public enum ICloudSyncOperations {
    /// Verification state reported by the subscription provider.
    public enum SubscriptionAccess: Sendable {
        case unknown
        case inactive
        case active
    }

    /// Retains the last known access when entitlement verification is unresolved.
    public static func updateSubscriptionAccess(
        _ access: SubscriptionAccess,
        store: MHPreferenceStore = .init()
    ) {
        switch access {
        case .unknown:
            return
        case .inactive:
            store.set(false, for: \.isSubscribeOn)
        case .active:
            store.set(true, for: \.isSubscribeOn)
        }
    }

    /// Selects the next process launch configuration without changing an open store.
    public static func isEnabledAtNextLaunch(
        store: MHPreferenceStore = .init()
    ) -> Bool {
        store.bool(for: \.isSubscribeOn)
            && store.bool(for: \.isICloudOn)
    }
}
