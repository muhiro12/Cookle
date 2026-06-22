import Foundation

/// Parses incoming URLs and maps them to app navigation routes.
public enum CookleRouteParser {
    /// Custom URL scheme accepted by the parser.
    public static let customScheme = CookleRouteURLDefaults.customScheme
    /// Universal-link hosts accepted by the parser.
    public static let universalLinkHosts: Set<String> = [
        CookleRouteURLDefaults.universalLinkHost
    ]

    /// Parses a URL into a route understood by the app.
    public static func parse(
        url: URL,
        allowedUniversalLinkHosts: Set<String> = universalLinkHosts
    ) -> CookleRoute? {
        let codec = CookleDeepLinkCodec.make(
            allowedUniversalLinkHosts: allowedUniversalLinkHosts
        )
        return codec.parse(url)
    }
}
