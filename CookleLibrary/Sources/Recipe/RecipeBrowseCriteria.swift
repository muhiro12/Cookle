import Foundation

/// Canonical browse criteria shared by recipe list and search surfaces.
public struct RecipeBrowseCriteria: Equatable, Sendable {
    public let searchText: String
    public let sortMode: RecipeBrowseSortMode
    public let isAscending: Bool

    public init(
        searchText: String,
        sortMode: RecipeBrowseSortMode,
        isAscending: Bool
    ) {
        self.searchText = searchText
        self.sortMode = sortMode
        self.isAscending = isAscending
    }
}
