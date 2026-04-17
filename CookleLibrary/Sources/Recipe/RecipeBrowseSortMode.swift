import Foundation

/// Supported sort modes for recipe browse and search surfaces.
public enum RecipeBrowseSortMode: String, CaseIterable, Identifiable, Sendable {
    case alphabetical
    case recentlyCreated
    case madeCount

    public var id: Self {
        self
    }
}
