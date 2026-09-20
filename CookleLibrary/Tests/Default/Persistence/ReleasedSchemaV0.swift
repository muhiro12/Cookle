@testable import CookleLibrary
import Foundation
import SwiftData

// Storage declarations from 2.7, before Photo.sourceID and versioned schemas.
// Preserve these declarations for users upgrading directly from older releases.
enum ReleasedSchemaV0: VersionedSchema {
    @Model
    final class Diary {
        var date = Date.now
        @Relationship(deleteRule: .cascade)
        var objects = [DiaryObject]?.some([])
        @Relationship var recipes = [Recipe]?.some([])
        var note = ""

        var createdTimestamp = Date.now
        var modifiedTimestamp = Date.now

        init() {
            // Fixture values are assigned before saving.
        }
    }

    @Model
    final class DiaryObject {
        @Relationship var recipe = Recipe?.none
        var type = DiaryObjectType?.none
        var order = Int.zero

        @Relationship(inverse: \Diary.objects)
        var diary = Diary?.none

        var createdTimestamp = Date.now
        var modifiedTimestamp = Date.now

        init() {
            // Fixture values are assigned before saving.
        }
    }

    @Model
    final class Photo {
        var data = Data()

        @Relationship(deleteRule: .cascade, inverse: \PhotoObject.photo)
        var objects = [PhotoObject]?.some([])
        @Relationship(inverse: \Recipe.photos)
        var recipes = [Recipe]?.some([])

        var createdTimestamp = Date.now
        var modifiedTimestamp = Date.now

        init() {
            // Fixture values are assigned before saving.
        }
    }

    @Model
    final class PhotoObject {
        @Relationship var photo = Photo?.none
        var order = Int.zero

        @Relationship(inverse: \Recipe.photoObjects)
        var recipe = Recipe?.none

        var createdTimestamp = Date.now
        var modifiedTimestamp = Date.now

        init() {
            // Fixture values are assigned before saving.
        }
    }

    @Model
    final class Recipe {
        var name = ""
        @Relationship var photos = [Photo]?.some([])
        @Relationship(deleteRule: .cascade)
        var photoObjects = [PhotoObject]?.some([])
        var servingSize = Int.zero
        var cookingTime = Int.zero
        @Relationship var ingredients = [Ingredient]?.some([])
        @Relationship(deleteRule: .cascade)
        var ingredientObjects = [IngredientObject]?.some([])
        var steps = [String]()
        @Relationship var categories = [Category]?.some([])
        var note = ""

        @Relationship(inverse: \Diary.recipes)
        var diaries = [Diary]?.some([])
        @Relationship(deleteRule: .cascade, inverse: \DiaryObject.recipe)
        var diaryObjects = [DiaryObject]?.some([])

        var createdTimestamp = Date.now
        var modifiedTimestamp = Date.now

        init() {
            // Fixture values are assigned before saving.
        }
    }

    @Model
    final class Category {
        var value = ""

        @Relationship(inverse: \Recipe.categories)
        var recipes = [Recipe]?.some([])

        var createdTimestamp = Date.now
        var modifiedTimestamp = Date.now

        init() {
            // Fixture values are assigned before saving.
        }
    }

    @Model
    final class Ingredient {
        var value = ""

        @Relationship(deleteRule: .cascade, inverse: \IngredientObject.ingredient)
        var objects = [IngredientObject]?.some([])
        @Relationship(inverse: \Recipe.ingredients)
        var recipes = [Recipe]?.some([])

        var createdTimestamp = Date.now
        var modifiedTimestamp = Date.now

        init() {
            // Fixture values are assigned before saving.
        }
    }

    @Model
    final class IngredientObject {
        @Relationship var ingredient = Ingredient?.none
        var amount = ""
        var order = Int.zero

        @Relationship(inverse: \Recipe.ingredientObjects)
        var recipe = Recipe?.none

        var createdTimestamp = Date.now
        var modifiedTimestamp = Date.now

        init() {
            // Fixture values are assigned before saving.
        }
    }

    static var versionIdentifier: Schema.Version {
        .init(0, 1, 0)
    }
    static var models: [any PersistentModel.Type] {
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
}
