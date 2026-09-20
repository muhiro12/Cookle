import CookleLibrary
import Foundation

/// Localized copy for errors raised inside a mutation operation.
///
/// `MHMutationWorkflow` converts an operation's error into a `String` before it
/// leaves the workflow, so every caller downstream receives an
/// `MHMutationWorkflowError` carrying that text and can no longer recognize the
/// original type. Translation therefore has to happen here, at the one point
/// where the concrete error is still available.
///
/// `CookleLibrary` declares no `defaultLocalization` and ships no string
/// catalog, so its `LocalizedError` descriptions are hardcoded English. Errors
/// named below are translated; anything else falls back to the library text.
nonisolated enum CookleMutationErrorCopy {
    static func description(for error: any Error) -> String {
        if let error = error as? DiaryDayConflictError {
            return description(for: error)
        }

        return error.localizedDescription
    }
}

nonisolated private extension CookleMutationErrorCopy {
    static func description(for error: DiaryDayConflictError) -> String {
        switch error {
        case .dayAlreadyOccupied:
            String(
                localized: "A diary already exists for this calendar day."
            )
        }
    }
}
