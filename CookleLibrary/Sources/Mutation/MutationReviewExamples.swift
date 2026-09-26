import Foundation
import SwiftData

/// Shared rules for the bounded examples a destructive-change review shows.
enum MutationReviewExamples {
    /// Most examples a review lists; the rest are only counted.
    static let limit = 3

    /// Returns the first names in display order, up to the example limit.
    static func names(
        _ names: [String]
    ) -> [String] {
        Array(
            names.sorted { lhs, rhs in
                lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
            .prefix(limit)
        )
    }

    /// Returns `models` with repeated records removed, keeping the first of each.
    static func uniqueModels<Model: PersistentModel>(
        _ models: [Model]
    ) -> [Model] {
        var seenIDs = Set<PersistentIdentifier>()
        return models.filter { model in
            seenIDs.insert(model.persistentModelID).inserted
        }
    }
}
