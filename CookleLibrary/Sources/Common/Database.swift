import Foundation
import SwiftData

public enum Database {
    public static let url = ModelConfiguration(
        groupContainer: .identifier(AppGroup.id)
    ).url

    public static let legacyURL = ModelConfiguration().url
}
