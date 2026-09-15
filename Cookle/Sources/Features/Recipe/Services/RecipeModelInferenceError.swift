import Foundation
import FoundationModels

@available(iOS 26.0, *)
enum RecipeModelInferenceError: LocalizedError {
    case contextLimit
    case unsupportedLanguage
    case rejectedInput
    case unavailable
    case retry

    var errorDescription: String? {
        switch self {
        case .contextLimit:
            String(
                localized: "This recipe text is too long to process. Keep only the recipe details and try again.",
                comment: "Recipe inference exceeded the model context limit."
            )
        case .unsupportedLanguage:
            String(
                localized: """
                Apple Intelligence cannot process this recipe's language. You can enter the recipe manually.
                """,
                comment: "Recipe inference does not support the input language."
            )
        case .rejectedInput:
            String(
                localized: """
                Apple Intelligence could not process this text. You can edit it or enter the recipe manually.
                """,
                comment: "Recipe inference was refused or blocked by model guardrails."
            )
        case .unavailable:
            String(
                localized: "Apple Intelligence is currently unavailable. Try again later or enter the recipe manually.",
                comment: "The model became unavailable during recipe inference."
            )
        case .retry:
            String(
                localized: "The recipe could not be generated. Try again or enter the recipe manually.",
                comment: "Recipe inference failed without producing a usable response."
            )
        }
    }

    init(error: any Error) {
        if #available(iOS 27.0, *) {
            if error is SystemLanguageModel.Error {
                self = .unavailable
            } else if let modelError = error as? LanguageModelError {
                switch modelError {
                case .contextSizeExceeded:
                    self = .contextLimit
                case .unsupportedLanguageOrLocale:
                    self = .unsupportedLanguage
                case .guardrailViolation, .refusal:
                    self = .rejectedInput
                default:
                    self = .retry
                }
            } else {
                self = .retry
            }
        } else {
            self.init(legacyError: error)
        }
    }

    @available(iOS, introduced: 26.0, obsoleted: 27.0)
    private init(legacyError error: any Error) {
        guard let generationError = error as? LanguageModelSession.GenerationError else {
            self = .retry
            return
        }
        switch generationError {
        case .exceededContextWindowSize:
            self = .contextLimit
        case .unsupportedLanguageOrLocale:
            self = .unsupportedLanguage
        case .guardrailViolation, .refusal:
            self = .rejectedInput
        case .assetsUnavailable:
            self = .unavailable
        default:
            self = .retry
        }
    }
}
