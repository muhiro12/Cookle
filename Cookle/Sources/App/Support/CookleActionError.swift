import CookleLibrary
import Foundation

enum CookleActionError: LocalizedError {
    case recipeNotFound
    case reviewedImpactChanged
    case unsupportedTagType(String)
    case missingMutationResult(String)

    var errorDescription: String? {
        switch self {
        case .recipeNotFound:
            return String(localized: "Recipe not found.")
        case .reviewedImpactChanged:
            return CookleLibraryErrorCopy.description(
                for: ReviewedMutationError.impactChanged
            )
        // The remaining cases guard invariants that only break through a
        // programming mistake, and they report Swift type and entity names,
        // so translating them would tell a reader less than the raw text.
        case .unsupportedTagType(let tagType):
            return "Unsupported tag type: \(tagType)."
        case .missingMutationResult(let entityName):
            return "\(entityName) could not be resolved after the mutation finished."
        }
    }
}
