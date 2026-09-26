import CookleLibrary
import Foundation

/// Localized copy for errors thrown by `CookleLibrary`.
///
/// The package declares no `defaultLocalization` and ships no string catalog, so
/// every `LocalizedError` it defines returns hardcoded English. Presenting
/// `error.localizedDescription` therefore puts untranslated text in front of the
/// user. This is the one place that names those errors and translates them;
/// anything it does not recognize falls back to the library text unchanged.
///
/// Two kinds of caller need it, for different reasons:
///
/// - Mutations, through `CookleMutationWorkflow`. `MHMutationWorkflow` converts
///   the operation's error into a `String` before returning, so the concrete
///   type is gone by the time any caller catches it. This runs as that
///   workflow's `operationErrorDescription`, which is the last point where the
///   error still has a type.
/// - Non-mutating operations such as recipe inference, which keep their concrete
///   error and can call this directly from their own `catch`.
nonisolated enum CookleLibraryErrorCopy {
    static func description(for error: any Error) -> String {
        if let conflict = error as? DiaryDayConflictError {
            return description(for: conflict)
        }

        if let inference = error as? RecipeInferenceError {
            return description(for: inference)
        }

        if let tag = error as? TagOperationsError {
            return description(for: tag)
        }

        if let reviewed = error as? ReviewedMutationError {
            return description(for: reviewed)
        }

        return error.localizedDescription
    }
}

nonisolated private extension CookleLibraryErrorCopy {
    static func description(for error: DiaryDayConflictError) -> String {
        switch error {
        case .dayAlreadyOccupied:
            String(
                localized: "A diary already exists for this calendar day."
            )
        }
    }

    static func description(for error: TagOperationsError) -> String {
        switch error {
        case .emptyValue:
            String(
                localized: "Value must not be empty."
            )
        case .ingredientInUse(let value):
            String(
                localized: "Ingredient \(value) is still used by recipes and cannot be deleted."
            )
        }
    }

    static func description(for error: ReviewedMutationError) -> String {
        switch error {
        case .targetMissing:
            String(
                localized: "This item no longer exists."
            )
        case .impactChanged:
            String(
                localized: "The affected items changed after you reviewed them. Review them again and try once more."
            )
        }
    }

    static func description(for error: RecipeInferenceError) -> String {
        switch error {
        case .emptyInput:
            String(
                localized: "Paste or import some recipe text first."
            )
        case .insufficientContent:
            String(
                localized: """
                Couldn't extract enough recipe details from the text.
                Try including the title, ingredients, or steps.
                """
            )
        case .modelUnavailable:
            String(
                localized: "Apple Intelligence is not available right now."
            )
        }
    }
}
