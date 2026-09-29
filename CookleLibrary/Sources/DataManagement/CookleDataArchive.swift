import Foundation

/// Validated, current-schema content of a Cookle data export file.
///
/// Records carry export-local identifiers and reference each other only within
/// the same file, so every archive is referentially complete whatever its scope.
public struct CookleDataArchive: Sendable {
    public struct IngredientRecord: Codable, Sendable {
        public let id: String
        public let value: String
        public let createdTimestamp: Date
        public let modifiedTimestamp: Date
    }

    public struct CategoryRecord: Codable, Sendable {
        public let id: String
        public let value: String
        public let createdTimestamp: Date
        public let modifiedTimestamp: Date
    }

    public struct PhotoRecord: Codable, Sendable {
        public let id: String
        public let data: Data
        public let sourceID: String
        public let createdTimestamp: Date
        public let modifiedTimestamp: Date
    }

    public struct RecipePhotoRecord: Codable, Sendable {
        public let photoID: String
        public let order: Int
        public let createdTimestamp: Date
        public let modifiedTimestamp: Date
    }

    public struct RecipeIngredientRecord: Codable, Sendable {
        public let ingredientID: String
        public let amount: String
        public let order: Int
        public let createdTimestamp: Date
        public let modifiedTimestamp: Date
    }

    public struct RecipeRecord: Codable, Sendable {
        public let id: String
        public let name: String
        public let photos: [RecipePhotoRecord]
        public let servingSize: Int
        public let cookingTime: Int
        public let ingredients: [RecipeIngredientRecord]
        public let steps: [String]
        public let categoryIDs: [String]
        public let note: String
        public let createdTimestamp: Date
        public let modifiedTimestamp: Date
    }

    public struct DiaryObjectRecord: Codable, Sendable {
        public let recipeID: String
        public let type: DiaryObjectType
        public let order: Int
        public let createdTimestamp: Date
        public let modifiedTimestamp: Date
    }

    public struct DiaryRecord: Codable, Sendable {
        public let id: String
        public let date: Date
        public let objects: [DiaryObjectRecord]
        public let note: String
        public let createdTimestamp: Date
        public let modifiedTimestamp: Date
    }

    /// Which part of the exporting library the records represent.
    public let scope: CookleDataArchiveScope
    public let exportedAt: Date
    public let ingredients: [IngredientRecord]
    public let categories: [CategoryRecord]
    public let photos: [PhotoRecord]
    public let recipes: [RecipeRecord]
    public let diaries: [DiaryRecord]
}
