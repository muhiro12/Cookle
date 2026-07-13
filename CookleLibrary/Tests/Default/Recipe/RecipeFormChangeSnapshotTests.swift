@testable import CookleLibrary
import Foundation
import Testing

struct RecipeFormChangeSnapshotTests {
    @Test
    func equivalentNumbersAndPlaceholderRowsAreNotChanges() {
        let initialSnapshot = snapshot(
            servingSize: "2",
            cookingTime: "",
            ingredients: [
                .init(ingredient: "Pasta", amount: "200g"),
                .init(ingredient: "", amount: "")
            ],
            steps: ["Boil", ""],
            categories: ["Dinner", ""]
        )
        let currentSnapshot = snapshot(
            servingSize: "０２",
            cookingTime: "0",
            ingredients: [
                .init(ingredient: "Pasta", amount: "200g"),
                .init(ingredient: "", amount: "ignored"),
                .init(ingredient: "", amount: "")
            ],
            steps: ["Boil", "", ""],
            categories: ["Dinner", "", ""]
        )

        #expect(currentSnapshot == initialSnapshot)
    }

    @Test
    func photoContentSourceAndOrderAreChanges() {
        let firstPhoto = PhotoData(
            data: Data("first".utf8),
            source: .photosPicker
        )
        let secondPhoto = PhotoData(
            data: Data("second".utf8),
            source: .imagePlayground
        )
        let initialSnapshot = snapshot(photos: [firstPhoto, secondPhoto])

        #expect(snapshot(photos: [secondPhoto, firstPhoto]) != initialSnapshot)
        #expect(
            snapshot(
                photos: [
                    .init(
                        data: firstPhoto.data,
                        source: .imagePlayground
                    ),
                    secondPhoto
                ]
            ) != initialSnapshot
        )
    }
}

private extension RecipeFormChangeSnapshotTests {
    func snapshot(
        photos: [PhotoData] = [],
        servingSize: String = "",
        cookingTime: String = "",
        ingredients: [RecipeFormIngredientInput] = [],
        steps: [String] = [],
        categories: [String] = []
    ) -> RecipeFormChangeSnapshot {
        .init(
            input: .init(
                name: "Recipe",
                photos: photos,
                servingSize: servingSize,
                cookingTime: cookingTime,
                ingredients: ingredients,
                steps: steps,
                categories: categories,
                note: "Note"
            )
        )
    }
}
