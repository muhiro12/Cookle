import Foundation
import MHPlatform

enum CookleIntentRouteStore {
    private static let pendingDeepLinkURLKey = StringPreferenceKey.pendingIntentDeepLinkURL.preferenceKey.storageKey
    private static let deepLinkStore = MHDeepLinkStore(
        userDefaults: .shared,
        key: pendingDeepLinkURLKey
    )

    static var source: MHDeepLinkStore {
        deepLinkStore
    }

    static func store(_ url: URL) {
        deepLinkStore.ingest(url)
    }
}
