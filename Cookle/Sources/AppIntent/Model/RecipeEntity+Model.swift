import SwiftData

extension RecipeEntity {
    func model(context: ModelContext) throws -> Recipe? {
        let identifier = try PersistentIdentifier(base64Encoded: id)
        return try context.fetchFirst(.recipes(.idIs(identifier)))
    }
}
