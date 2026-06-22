import Foundation

enum CookleRouteIntentSupport {
    static func open(_ route: CookleRoute) {
        CookleIntentRouteStore.store(
            CookleDeepLinkURLBuilder.preferredURL(for: route)
        )
    }
}
