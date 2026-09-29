@testable import CookleLibrary
import Foundation
import SwiftData

/// Encodes an archive's records, ignoring its scope and export time, so the
/// content of two stores can be compared byte for byte.
enum TestArchiveContent {
    private struct Content: Encodable {
        let ingredients: [CookleDataArchive.IngredientRecord]
        let categories: [CookleDataArchive.CategoryRecord]
        let photos: [CookleDataArchive.PhotoRecord]
        let recipes: [CookleDataArchive.RecipeRecord]
        let diaries: [CookleDataArchive.DiaryRecord]
    }

    static func data(
        of archive: CookleDataArchive
    ) throws -> Data {
        try CookleDataArchiveService.encoder.encode(
            Content(
                ingredients: archive.ingredients,
                categories: archive.categories,
                photos: archive.photos,
                recipes: archive.recipes,
                diaries: archive.diaries
            )
        )
    }

    @MainActor
    static func data(
        storedIn context: ModelContext
    ) throws -> Data {
        try data(
            of: CookleDataArchiveService.makeArchive(
                context: context
            )
        )
    }
}
