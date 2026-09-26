import Foundation

/// Formats the bounded examples a destructive-change review shows.
enum ReviewExampleCopy {
    /// Notice shown when a confirmation reopens because the affected items changed.
    static var changedNotice: String {
        String(
            localized: "The affected items changed. Review the updated details before confirming again."
        )
    }

    /// Lists `examples` and counts the affected items they leave out.
    static func list(
        _ examples: [String],
        totalCount: Int
    ) -> String {
        let remainingCount = totalCount - examples.count
        guard remainingCount > .zero else {
            return examples.formatted(.list(type: .and))
        }

        return (examples + [String(localized: "\(remainingCount) more")])
            .formatted(.list(type: .and))
    }

    /// Message shown when the reviewed item disappeared before confirmation.
    static func missingMessage(
        for name: String
    ) -> String {
        String(localized: "\(name) no longer exists. Nothing was changed.")
    }
}
