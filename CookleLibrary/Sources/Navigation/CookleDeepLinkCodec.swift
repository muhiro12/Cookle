import MHPlatformCore

enum CookleDeepLinkCodec {
    static let shared = make()

    static func make(
        host: String = CookleRouteURLDefaults.universalLinkHost,
        allowedUniversalLinkHosts: Set<String> = [
            CookleRouteURLDefaults.universalLinkHost
        ],
        appPathPrefix: String = CookleRouteURLDefaults.universalLinkPathPrefix,
        preferredTransport: MHDeepLinkTransport = .universalLink
    ) -> MHDeepLinkCodec<CookleRoute> {
        .init(
            configuration: .init(
                customScheme: CookleRouteURLDefaults.customScheme,
                preferredUniversalLinkHost: host,
                allowedUniversalLinkHosts: allowedUniversalLinkHosts,
                universalLinkPathPrefix: appPathPrefix,
                preferredTransport: preferredTransport
            )
        )
    }
}
