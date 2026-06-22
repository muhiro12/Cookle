import Foundation
import MHPlatform

enum CookleIntentRouteStore {
    private static let pendingDeepLinkURLKey = MHPreferenceDescriptors()
        .pendingIntentDeepLinkURL
        .storageKey
    private static let userDefaults = MHUserDefaultsSelection
        .suite(UserDefaults.appGroupIdentifier)
        .resolveUserDefaults()
    private static let deepLinkStore = MHDeepLinkStore(
        userDefaults: userDefaults,
        key: pendingDeepLinkURLKey
    )

    static var source: MHDeepLinkStore {
        deepLinkStore
    }

    static func store(_ url: URL) {
        deepLinkStore.ingest(url)
    }
}
