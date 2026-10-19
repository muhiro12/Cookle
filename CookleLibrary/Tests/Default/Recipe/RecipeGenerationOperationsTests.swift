import CookleLibrary
import Testing

@MainActor
struct RecipeGenerationOperationsTests {
    @Test
    func a_creative_draft_keeps_details_not_supplied_in_the_request() throws {
        let draft = try #require(RecipeGenerationOperations.preparedDraft(from: recipe))

        #expect(draft.name == "Tofu with mushrooms")
        #expect(draft.servingSize == 2)
        #expect(draft.cookingTime == 15)
        #expect(draft.ingredients.first?.amount == "300 g")
        #expect(draft.steps == ["Simmer the tofu and mushrooms."])
    }

    @Test(arguments: ["name", "ingredients", "steps"])
    func incomplete_output_cannot_replace_the_form(missingField: String) {
        var generated = recipe
        switch missingField {
        case "name":
            generated.name = " \n "
        case "ingredients":
            generated.ingredients = [.init(ingredient: " ", amount: "300 g")]
        default:
            generated.steps = ["\n"]
        }

        #expect(RecipeGenerationOperations.preparedDraft(from: generated) == nil)
    }

    @Test
    func generated_list_markers_do_not_repeat_editor_numbers_or_remove_quantities() throws {
        var generated = recipe
        generated.steps = ["1. Cook tofu.", "２） Stir.", "- Serve.", "1.5 tbsp oil goes into the pan."]
        let draft = try #require(RecipeGenerationOperations.preparedDraft(from: generated))

        #expect(draft.steps == ["Cook tofu.", "Stir.", "Serve.", "1.5 tbsp oil goes into the pan."])
    }

    @Test
    func list_markers_alone_are_not_usable_cooking_steps() {
        var generated = recipe
        generated.steps = ["1. ", "- "]

        #expect(RecipeGenerationOperations.preparedDraft(from: generated) == nil)
    }

    @Test
    func a_generated_draft_can_be_edited_and_undone_like_an_import() throws {
        let draft = try #require(RecipeGenerationOperations.preparedDraft(from: recipe))
        let previous = RecipeFormInput(
            name: "My dinner",
            photos: [],
            servingSize: "4",
            cookingTime: "",
            ingredients: [],
            steps: [],
            categories: [],
            note: "Use what is left."
        )
        #expect(RecipeFormOperations.inferenceReplacesEnteredValues(in: previous))
        let application = RecipeFormOperations.applyInference(draft, sourceURL: nil, to: previous)
        var edited = application.appliedInput
        edited.note = "Use more mushrooms next time."

        #expect(application.hasEdits(in: edited))
        #expect(application.previousInput.name == previous.name)
        #expect(application.previousInput.note == previous.note)
        #expect(application.appliedInput.name == draft.name)
        #expect(application.appliedInput.ingredients.first?.amount == "300 g")
    }
}

private extension RecipeGenerationOperationsTests {
    var recipe: RecipeInferenceResult {
        let servingSize = 2
        let cookingTime = 15
        return .init(
            name: "Tofu with mushrooms",
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredients: [.init(ingredient: "Tofu", amount: "300 g")],
            steps: ["Simmer the tofu and mushrooms."],
            categories: [],
            note: "Adjust seasoning after cooking."
        )
    }
}
