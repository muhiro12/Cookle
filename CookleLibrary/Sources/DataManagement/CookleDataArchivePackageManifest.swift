import Foundation

struct CookleDataArchivePackageManifest: Codable, Sendable {
    /// Leading fields decoded on their own, so a file from a newer schema is
    /// identified before its records are decoded.
    struct Header: Decodable, Sendable {
        let format: String
        let formatVersion: Int
        let schemaVersion: String
    }

    struct Contents: Codable, Sendable {
        let scope: String
    }

    struct PhotoRecord: Codable, Sendable {
        let id: String
        let filename: String
        let byteCount: Int
        let sha256: String
        let sourceID: String
        let createdTimestamp: Date
        let modifiedTimestamp: Date
    }

    /// Identifies a Cookle data export independently of its file extension.
    static let formatIdentifier = "com.muhiro12.cookle.data"
    /// Version of the package layout; record shapes follow `schemaVersion`.
    static let currentFormatVersion = 1

    let format: String
    let formatVersion: Int
    let schemaVersion: String
    let contents: Contents
    let exportedAt: Date
    let ingredients: [CookleDataArchive.IngredientRecord]
    let categories: [CookleDataArchive.CategoryRecord]
    let photos: [PhotoRecord]
    let recipes: [CookleDataArchive.RecipeRecord]
    let diaries: [CookleDataArchive.DiaryRecord]
}
