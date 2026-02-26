import Foundation
import SwiftData

public enum Database {
    public static let url = ModelConfiguration().url

    public static let legacyURL = URL.applicationSupportDirectory.appendingPathComponent(
        url.lastPathComponent
    )
}
