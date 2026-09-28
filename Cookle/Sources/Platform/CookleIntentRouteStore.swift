import Foundation
import MHPlatform

enum CookleIntentRouteStore {
    private static let pendingDeepLinkURLDescriptor = MHPreferenceDescriptors()
        .pendingIntentDeepLinkURL
    private static let deepLinkStore = MHDeepLinkStore(
        selection: pendingDeepLinkURLDescriptor.defaultSelection,
        key: pendingDeepLinkURLDescriptor.storageKey
    )

    static var source: MHDeepLinkStore {
        deepLinkStore
    }

    static func store(_ url: URL) {
        deepLinkStore.ingest(url)
    }
}
