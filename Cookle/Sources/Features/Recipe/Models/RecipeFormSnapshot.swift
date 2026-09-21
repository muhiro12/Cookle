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

    /// Indicates the draft holds nothing worth restoring.
    ///
    /// The form always keeps a trailing blank row for ingredients and steps, so
    /// these lists are never actually empty. Treating a list of placeholders as
    /// content would let a form that has only just opened overwrite the draft
    /// the Restore Draft button exists to bring back.
    var isEmpty: Bool {
        let values = [name, servingSize, cookingTime, note]
        return values.allSatisfy(Self.isBlank)
            && ingredients.allSatisfy { ingredient in
                Self.isBlank(ingredient.ingredient) && Self.isBlank(ingredient.amount)
            }
            && steps.allSatisfy(Self.isBlank)
            && categories.allSatisfy(Self.isBlank)
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

nonisolated private extension RecipeFormSnapshot {
    static func isBlank(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
