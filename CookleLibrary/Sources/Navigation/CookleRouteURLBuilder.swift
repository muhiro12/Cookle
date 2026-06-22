import Foundation

/// Builds shareable URLs from app routes.
public enum CookleRouteURLBuilder {
    /// Default custom URL scheme used by the app.
    public static let customScheme = CookleRouteURLDefaults.customScheme
    /// Default host used for universal links.
    public static let defaultUniversalLinkHost = CookleRouteURLDefaults.universalLinkHost
    /// Default universal-link path prefix for app routes.
    public static let defaultUniversalLinkPathPrefix =
        CookleRouteURLDefaults.universalLinkPathPrefix

    /// Builds a custom-scheme URL for the supplied route.
    public static func customSchemeURL(
        for route: CookleRoute
    ) -> URL? {
        legacyCompatibleURL(
            route: route,
            builtURL: CookleDeepLinkCodec.shared.url(
                for: route,
                transport: .customScheme
            )
        )
    }

    /// Builds a universal-link URL for the supplied route.
    public static func universalLinkURL(
        for route: CookleRoute,
        host: String = defaultUniversalLinkHost,
        appPathPrefix: String = defaultUniversalLinkPathPrefix
    ) -> URL? {
        let codec = CookleDeepLinkCodec.make(
            host: host,
            appPathPrefix: appPathPrefix
        )
        return legacyCompatibleURL(
            route: route,
            builtURL: codec.url(
                for: route,
                transport: .universalLink
            )
        )
    }

    private static func legacyCompatibleURL(
        route: CookleRoute,
        builtURL: URL?
    ) -> URL? {
        guard let builtURL else {
            return nil
        }
        guard route.deepLinkDescriptor.queryItems.isEmpty,
              builtURL.absoluteString.hasSuffix("?") == false else {
            return builtURL
        }
        return URL(string: builtURL.absoluteString + "?")
    }
}
