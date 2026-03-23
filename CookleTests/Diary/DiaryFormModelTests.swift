import CookleLibrary
import Testing

@testable import Cookle

@MainActor
struct DiaryFormModelTests {
    @Test
    func applyInitialValues_populatesMealsAndDoesNotReapply() throws {
        let context = try makeCookleTestContext()
        let breakfast = Recipe.create(
            context: context,
            name: "Toast",
            photos: [],
            servingSize: 1,
            cookingTime: 5,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        let dinner = Recipe.create(
            context: context,
            name: "Soup",
            photos: [],
            servingSize: 2,
            cookingTime: 20,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        let diary = DiaryService.create(
            context: context,
            date: .now,
            breakfasts: [breakfast],
            lunches: [],
            dinners: [dinner],
            note: "Initial"
        )
        let model = DiaryFormModel()

        model.applyInitialValues(
            diary: diary
        )

        #expect(model.breakfasts == Set([breakfast]))
        #expect(model.dinners == Set([dinner]))
        #expect(model.note == "Initial")

        model.note = "Changed"
        model.applyInitialValues(
            diary: diary
        )

        #expect(model.note == "Changed")
    }
}
