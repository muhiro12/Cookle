import Foundation
import SwiftData

public enum Database {
    public static let url = ModelConfiguration(
        groupContainer: .identifier(AppGroup.id)
    ).url

    static let legacyURL = ModelConfiguration().url
}
