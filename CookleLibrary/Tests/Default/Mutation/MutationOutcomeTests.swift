@testable import CookleLibrary
import Testing

struct MutationOutcomeTests {
    @Test
    func stores_value_and_effects() {
        let outcome = MutationOutcome(
            value: "Recipe",
            effects: [
                .recipeDataChanged,
                .notificationPlanChanged
            ]
        )

        #expect(outcome.value == "Recipe")
        #expect(outcome.effects.contains(.recipeDataChanged))
        #expect(outcome.effects.contains(.notificationPlanChanged))
        #expect(!outcome.effects.contains(.reviewPromptEligible))
    }

    @Test
    func supports_void_value() {
        let outcome = MutationOutcome(
            value: (),
            effects: [.diaryDataChanged]
        )

        #expect(outcome.effects.contains(.diaryDataChanged))
    }
}
