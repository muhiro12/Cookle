import Foundation

enum CookleIntentRouteStore {
    private static let pendingDeepLinkURLKey = "pendingCookleIntentDeepLinkURL"

    static func store(_ url: URL) {
        guard let userDefaults = UserDefaults(
            suiteName: CookleSharedPreferences.appGroupIdentifier
        ) else {
            return
        }
        userDefaults.set(
            url.absoluteString,
            forKey: pendingDeepLinkURLKey
        )
    }

    static func consume() -> URL? {
        guard let userDefaults = UserDefaults(
            suiteName: CookleSharedPreferences.appGroupIdentifier
        ) else {
            return nil
        }
        defer {
            userDefaults.removeObject(forKey: pendingDeepLinkURLKey)
        }
        guard let deepLinkURLString = userDefaults.string(
            forKey: pendingDeepLinkURLKey
        ) else {
            return nil
        }
        return .init(string: deepLinkURLString)
    }
}
