import Foundation

/// Domain mutation signals consumed by target adapters.
public struct MutationEffect: OptionSet, Sendable {
    /// Indicates recipe-domain records changed.
    public static let recipeDataChanged: MutationEffect = .init(rawValue: 1 << 0)
    /// Indicates diary-domain records changed.
    public static let diaryDataChanged: MutationEffect = .init(rawValue: 1 << 1)
    /// Indicates notification planning should be refreshed.
    public static let notificationPlanChanged: MutationEffect = .init(rawValue: 1 << 2)
    /// Indicates review prompting can be attempted.
    public static let reviewPromptEligible: MutationEffect = .init(rawValue: 1 << 3)

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
