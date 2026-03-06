import Foundation
import MHPlatform

enum CookleIntentRouteStore {
    private static let pendingDeepLinkURLKey = "pendingCookleIntentDeepLinkURL"
    private static var deepLinkStore: MHDeepLinkStore? {
        guard let userDefaults = UserDefaults(
            suiteName: CookleSharedPreferences.appGroupIdentifier
        ) else {
            return nil
        }
        return .init(
            userDefaults: userDefaults,
            key: pendingDeepLinkURLKey
        )
    }

    static func store(_ url: URL) {
        deepLinkStore?.ingest(url)
    }

    static func consume() -> URL? {
        deepLinkStore?.consumeLatest()
    }
}
