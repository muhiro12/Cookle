import Foundation
import SwiftData

/// Deprecated search entrypoint kept for callers that have not migrated to `RecipeService`.
@preconcurrency
@MainActor
@available(*, deprecated, message: "Use RecipeService.search(context:text:) instead")
public enum SearchService {
    /// Forwards legacy search callers to `RecipeService.search(context:text:)`.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - text: Search text.
    /// - Returns: Matching recipes (deduplicated).
    public static func search(context: ModelContext, text: String) throws -> [Recipe] {
        try RecipeService.search(
            context: context,
            text: text
        )
    }
}
