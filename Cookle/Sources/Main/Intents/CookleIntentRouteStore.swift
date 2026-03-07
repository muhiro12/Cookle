import Foundation
import MHPlatform

enum CookleIntentRouteStore {
    private static let pendingDeepLinkURLKey = "pendingCookleIntentDeepLinkURL"
    private static let deepLinkStore = MHDeepLinkStore(
        suiteName: CookleSharedPreferences.appGroupIdentifier,
        key: pendingDeepLinkURLKey
    )

    static func store(_ url: URL) {
        deepLinkStore?.ingest(url)
    }

    static func consume() -> URL? {
        deepLinkStore?.consumeLatest()
    }
}
