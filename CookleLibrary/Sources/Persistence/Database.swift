import Foundation
import SwiftData

/// Canonical store URLs used by the app and migration helpers.
public enum Database {
    /// Current SwiftData store URL.
    ///
    /// `ModelConfiguration()` defaults `groupContainer` to `.automatic`, which
    /// resolves to the single app group in the target's entitlements. The app
    /// and the Widgets extension therefore open the same file only because both
    /// declare `group.com.muhiro12.Cookle` and nothing else. Declaring a second
    /// group on either target, or dropping the entitlement, would silently move
    /// this URL into a per-process container and split the store with no error.
    public static let url = ModelConfiguration().url

    /// Legacy store URL migrated from older app versions.
    public static let legacyURL = URL.applicationSupportDirectory.appendingPathComponent(
        url.lastPathComponent
    )
}
