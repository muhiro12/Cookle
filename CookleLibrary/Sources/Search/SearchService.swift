import Foundation
import SwiftData

/// Deprecated wrapper around `RecipeService.search(context:text:)`.
@preconcurrency
@MainActor
@available(*, deprecated, message: "Use RecipeService.search(context:text:) instead")
public enum SearchService {
    /// Searches recipes using the canonical recipe search service.
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
