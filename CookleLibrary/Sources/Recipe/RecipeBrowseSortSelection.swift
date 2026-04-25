import Foundation

/// Persisted browse sort selection combining mode and direction into one value.
public enum RecipeBrowseSortSelection: String, CaseIterable, Identifiable, Sendable {
    case alphabeticalAscending
    case alphabeticalDescending
    case recentlyCreatedAscending
    case recentlyCreatedDescending
    case madeCountAscending
    case madeCountDescending

    public var id: Self {
        self
    }

    public var sortMode: RecipeBrowseSortMode {
        switch self {
        case .alphabeticalAscending,
             .alphabeticalDescending:
            .alphabetical
        case .recentlyCreatedAscending,
             .recentlyCreatedDescending:
            .recentlyCreated
        case .madeCountAscending,
             .madeCountDescending:
            .madeCount
        }
    }

    public var isAscending: Bool {
        switch self {
        case .alphabeticalAscending,
             .recentlyCreatedAscending,
             .madeCountAscending:
            true
        case .alphabeticalDescending,
             .recentlyCreatedDescending,
             .madeCountDescending:
            false
        }
    }

    public init(
        sortMode: RecipeBrowseSortMode,
        isAscending: Bool
    ) {
        switch (sortMode, isAscending) {
        case (.alphabetical, true):
            self = .alphabeticalAscending
        case (.alphabetical, false):
            self = .alphabeticalDescending
        case (.recentlyCreated, true):
            self = .recentlyCreatedAscending
        case (.recentlyCreated, false):
            self = .recentlyCreatedDescending
        case (.madeCount, true):
            self = .madeCountAscending
        case (.madeCount, false):
            self = .madeCountDescending
        }
    }
}
