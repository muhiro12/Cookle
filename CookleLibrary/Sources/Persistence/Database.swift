import Foundation
import SwiftData

/// Canonical store URLs used by the app and migration helpers.
public enum Database {
    /// Current SwiftData store URL.
    public static let url = ModelConfiguration().url

    /// Legacy store URL migrated from older app versions.
    public static let legacyURL = URL.applicationSupportDirectory.appendingPathComponent(
        url.lastPathComponent
    )
}
