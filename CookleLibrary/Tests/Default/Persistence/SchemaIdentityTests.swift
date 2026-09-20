@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Freezes the released storage contract.
///
/// `CookleSchemaV1.models` points at the live model classes, so editing any
/// stored declaration silently changes the schema that shipped installs opened
/// their store with. These tests pin the entity and property names so that the
/// drift fails here rather than at a user's first launch after an update.
///
/// A deliberate V2 is expected to update these expectations in the same commit
/// that adds the migration stage.
struct SchemaIdentityTests {
    @Test
    func released_schema_version_identifier_is_unchanged() {
        let schema = Schema(versionedSchema: CookleSchemaV1.self)
        #expect(schema.version == .init(1, 0, 0))
    }

    @Test
    func released_schema_entity_names_are_unchanged() {
        let schema = Schema(versionedSchema: CookleSchemaV1.self)
        #expect(schema.entities.map(\.name).sorted() == Self.releasedProperties.keys.sorted())
    }

    @Test
    func released_schema_property_names_are_unchanged() {
        let schema = Schema(versionedSchema: CookleSchemaV1.self)
        for entity in schema.entities.sorted(by: { $0.name < $1.name }) {
            let expected = Self.releasedProperties[entity.name]
            #expect(entity.properties.map(\.name).sorted() == expected, "\(entity.name)")
        }
    }
}

private extension SchemaIdentityTests {
    /// Property names of every entity in the released V1 schema.
    static let releasedProperties: [String: [String]] = [
        "Category": [
            "createdTimestamp", "modifiedTimestamp", "recipes", "value"
        ],
        "Diary": [
            "createdTimestamp", "date", "modifiedTimestamp", "note", "objects", "recipes"
        ],
        "DiaryObject": [
            "createdTimestamp", "diary", "modifiedTimestamp", "order", "recipe", "type"
        ],
        "Ingredient": [
            "createdTimestamp", "modifiedTimestamp", "objects", "recipes", "value"
        ],
        "IngredientObject": [
            "amount", "createdTimestamp", "ingredient", "modifiedTimestamp", "order", "recipe"
        ],
        "Photo": [
            "createdTimestamp", "data", "modifiedTimestamp", "objects", "recipes", "sourceID"
        ],
        "PhotoObject": [
            "createdTimestamp", "modifiedTimestamp", "order", "photo", "recipe"
        ],
        "Recipe": [
            "categories", "cookingTime", "createdTimestamp", "diaries", "diaryObjects",
            "ingredientObjects", "ingredients", "modifiedTimestamp", "name", "note",
            "photoObjects", "photos", "servingSize", "steps"
        ]
    ]
}
