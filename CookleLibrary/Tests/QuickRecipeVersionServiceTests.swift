@testable import CookleLibrary
import Testing

struct QuickRecipeVersionServiceTests {
    @available(iOS 26.0, *)
    @Test
    func normalizedRequest_removesEmptyStepsAndIngredients() {
        let request = QuickRecipeVersionService.normalizedRequest(
            .init(
                name: "  Curry Rice  ",
                cookingTime: 30,
                ingredients: [
                    " Onion ",
                    ""
                ],
                steps: [
                    " 1. Chop onion ",
                    ""
                ]
            )
        )

        #expect(request.name == "Curry Rice")
        #expect(request.ingredients == ["Onion"])
        #expect(request.steps == ["Chop onion"])
    }

    @available(iOS 26.0, *)
    @Test
    func fallbackVersion_condensesLongStepListsAndEstimatesShorterTime() {
        let version = QuickRecipeVersionService.fallbackVersion(
            request: .init(
                name: "Curry Rice",
                cookingTime: 30,
                ingredients: [],
                steps: [
                    "Chop onion.",
                    "Brown meat.",
                    "Add vegetables.",
                    "Simmer.",
                    "Serve with rice."
                ]
            )
        )

        #expect(version.summary == "A shorter view of Curry Rice for quick reference.")
        #expect(version.estimatedCookingTime == 20)
        #expect(version.steps == [
            "Chop onion.",
            "Brown meat.",
            "Serve with rice."
        ])
    }

    @available(iOS 26.0, *)
    @Test
    func sanitizedVersion_usesFallbackTimeWhenGeneratedTimeIsMissing() {
        let request = QuickRecipeVersionRequest(
            name: "Soup",
            cookingTime: 15,
            ingredients: [],
            steps: [
                "Prep.",
                "Cook."
            ]
        )
        let version = QuickRecipeVersionService.sanitizedVersion(
            .init(
                summary: "",
                estimatedCookingTime: .zero,
                steps: [
                    " Prep quickly ",
                    ""
                ]
            ),
            request: request
        )

        #expect(version?.summary == "A shorter view of Soup for quick reference.")
        #expect(version?.estimatedCookingTime == 10)
        #expect(version?.steps == ["Prep quickly"])
    }
}
