import Foundation

/// Shared defaults used by route URL parsing and building.
public enum CookleRouteURLDefaults {
    public static let customScheme = "cookle"
    public static let universalLinkHost = "muhiro12.github.io"
    public static let universalLinkAssociatedDomainPrefix = "applinks"
    public static let universalLinkPathPrefix = "Cookle"

    public static var universalLinkAssociatedDomain: String {
        "\(universalLinkAssociatedDomainPrefix):\(universalLinkHost)"
    }
}
