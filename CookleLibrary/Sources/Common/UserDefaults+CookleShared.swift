import Foundation

public extension UserDefaults {
    /// The app group identifier used for shared `UserDefaults` access.
    static var appGroupIdentifier: String {
        AppGroup.id
    }
}
