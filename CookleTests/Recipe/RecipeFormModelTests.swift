import CookleLibrary
import Foundation
import Testing

@testable import Cookle

@MainActor
struct RecipeFormModelTests {
    @Test
    func applyRecipeIfNeeded_populatesFormStateOnce() throws {
        let context = try makeCookleTestContext()
        let recipe = Recipe.create(
            context: context,
            name: "Pasta",
            photos: [],
            servingSize: 2,
            cookingTime: 15,
            ingredients: [
                IngredientObject.create(
                    context: context,
                    ingredient: "Spaghetti",
                    amount: "100g",
                    order: 1
                )
            ],
            steps: ["Boil water", "Cook pasta"],
            categories: [
                Category.create(
                    context: context,
                    value: "Dinner"
                )
            ],
            note: "Classic"
        )
        let model = RecipeFormModel(
            type: .edit
        )

        model.applyRecipeIfNeeded(
            recipe
        )

        #expect(model.name == "Pasta")
        #expect(model.servingSize == "2")
        #expect(model.cookingTime == "15")
        #expect(model.ingredients.first?.ingredient == "Spaghetti")
        #expect(Array(model.steps.prefix(2)) == ["Boil water", "Cook pasta"])
        #expect(model.categories.first == "Dinner")
        #expect(model.note == "Classic")

        model.name = "Changed"
        model.applyRecipeIfNeeded(
            recipe
        )

        #expect(model.name == "Changed")
    }

    @Test
    func applyRecipeIfNeeded_populatesPhotosInStoredDisplayOrder() throws {
        let context = try makeCookleTestContext()
        let secondPhotoObject = PhotoObject.create(
            context: context,
            photoData: makePhotoData("second"),
            order: 2
        )
        let firstPhotoObject = PhotoObject.create(
            context: context,
            photoData: makePhotoData("first"),
            order: 1
        )
        let recipe = Recipe.create(
            context: context,
            name: "Pasta",
            photos: [
                secondPhotoObject,
                firstPhotoObject
            ],
            servingSize: 2,
            cookingTime: 15,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        let model = RecipeFormModel(
            type: .edit
        )

        model.applyRecipeIfNeeded(
            recipe
        )

        #expect(model.photos.map(\.data) == [data("first"), data("second")])
    }
}

private extension RecipeFormModelTests {
    func makePhotoData(
        _ identifier: String
    ) -> PhotoData {
        .init(
            data: data(identifier),
            source: .photosPicker
        )
    }

    func data(
        _ identifier: String
    ) -> Data {
        Data(identifier.utf8)
    }
}
