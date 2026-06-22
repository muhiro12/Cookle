import Foundation
import MHPlatform

nonisolated struct RecipeFormSnapshot: Codable, Equatable, Sendable {
    nonisolated struct Ingredient: Codable, Equatable, Sendable {
        let ingredient: String
        let amount: String
        var formIngredient: RecipeFormIngredient {
            .init(
                ingredient: ingredient,
                amount: amount
            )
        }

        init(
            ingredient: String,
            amount: String
        ) {
            self.ingredient = ingredient
            self.amount = amount
        }

        init(
            _ ingredientInput: RecipeFormIngredient
        ) {
            self.init(
                ingredient: ingredientInput.ingredient,
                amount: ingredientInput.amount
            )
        }
    }

    static let preferenceDescriptor = MHCodablePreferenceDescriptor<Self>(
        storageKey: CookleUserDefaultsKeys.Standard.recipeFormSnapshot.rawValue,
        defaultSelection: .standard
    )

    let name: String
    let servingSize: String
    let cookingTime: String
    let ingredients: [Ingredient]
    let steps: [String]
    let categories: [String]
    let note: String
    var formIngredients: [RecipeFormIngredient] {
        ingredients.map(\.formIngredient)
    }

    init(
        name: String,
        servingSize: String,
        cookingTime: String,
        ingredients: [RecipeFormIngredient],
        steps: [String],
        categories: [String],
        note: String
    ) {
        self.name = name
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients.map(
            Ingredient.init
        )
        self.steps = steps
        self.categories = categories
        self.note = note
    }
}
extension FormSnapshotStore where Snapshot == RecipeFormSnapshot {
    init(
        userDefaults: UserDefaults = .standard
    ) {
        self.init(
            descriptor: RecipeFormSnapshot.preferenceDescriptor,
            userDefaults: userDefaults
        )
    }
}
