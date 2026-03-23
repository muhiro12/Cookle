import Foundation

enum CookleActionError: LocalizedError {
    case recipeNotFound
    case unsupportedTagType(String)
    case missingMutationResult(String)

    var errorDescription: String? {
        switch self {
        case .recipeNotFound:
            return "Recipe not found."
        case .unsupportedTagType(let tagType):
            return "Unsupported tag type: \(tagType)."
        case .missingMutationResult(let entityName):
            return "\(entityName) could not be resolved after the mutation finished."
        }
    }
}
