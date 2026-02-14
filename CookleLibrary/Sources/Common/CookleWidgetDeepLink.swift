import Foundation

/// Widget destinations that can be opened from a widget tap.
public enum CookleWidgetDestination: String, Sendable {
    case diary
    case recipe
}

/// Deep-link helper shared by the app and widget extension.
public enum CookleWidgetDeepLink {
    public static let scheme = "cookle"

    private static let host = "widget"

    /// Creates a deep-link URL for a widget destination.
    public static func url(for destination: CookleWidgetDestination) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/\(destination.rawValue)"
        return components.url
    }

    /// Extracts a widget destination from a deep-link URL.
    public static func destination(from deepLinkURL: URL) -> CookleWidgetDestination? {
        guard deepLinkURL.scheme?.lowercased() == scheme,
              deepLinkURL.host?.lowercased() == host else {
            return nil
        }

        let destinationPath = deepLinkURL.path.trimmingCharacters(
            in: .init(charactersIn: "/")
        )
        return .init(rawValue: destinationPath)
    }
}
