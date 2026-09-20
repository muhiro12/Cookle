import SwiftData

/// Released storage contract. Preserve stored declarations when introducing V2.
/// Current model aliases and behavior extensions do not define a new schema version.
public enum CookleSchemaV1: VersionedSchema {
    public static var models: [any PersistentModel.Type] {
        [
            Diary.self,
            DiaryObject.self,
            Photo.self,
            PhotoObject.self,
            Recipe.self,
            Category.self,
            Ingredient.self,
            IngredientObject.self
        ]
    }

    public static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }
}
