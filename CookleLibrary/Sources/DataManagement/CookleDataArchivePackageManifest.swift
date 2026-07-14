import Foundation

struct CookleDataArchivePackageManifest: Codable, Sendable {
    struct PhotoRecord: Codable, Sendable {
        let id: String
        let filename: String
        let byteCount: Int
        let sha256: String
        let sourceID: String
        let createdTimestamp: Date
        let modifiedTimestamp: Date
    }

    static let currentPackageFormatVersion = 2

    let packageFormatVersion: Int
    let archiveFormatVersion: Int
    let exportedAt: Date
    let ingredients: [CookleDataArchive.IngredientRecord]
    let categories: [CookleDataArchive.CategoryRecord]
    let photos: [PhotoRecord]
    let recipes: [CookleDataArchive.RecipeRecord]
    let diaries: [CookleDataArchive.DiaryRecord]
}
