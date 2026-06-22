import Foundation

/// Shared defaults used by route URL parsing and building.
public enum CookleRouteURLDefaults {
    /// Custom URL scheme used by Cookle deep links.
    public static let customScheme = "cookle"
    /// Host used by universal-link deep links.
    public static let universalLinkHost = "muhiro12.github.io"
    /// Associated-domain prefix used for universal-link entitlements.
    public static let universalLinkAssociatedDomainPrefix = "applinks"
    /// Path prefix used when building universal-link URLs.
    public static let universalLinkPathPrefix = "Cookle"

    /// Full associated-domain string used by app entitlements.
    public static var universalLinkAssociatedDomain: String {
        "\(universalLinkAssociatedDomainPrefix):\(universalLinkHost)"
    }
}
