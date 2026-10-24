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

    @Test
    func complete_fields_do_not_trigger_a_culinary_rewrite() async throws {
        var repairs = 0
        let draft = try await RecipeGenerationOperations.validatedDraft(from: recipe) { _, _ in
            repairs += 1
            return recipe
        }

        #expect(draft == recipe)
        #expect(repairs == 0)
        #expect(RecipeGenerationOperations.draftIssues(in: recipe).isEmpty)
    }

    @Test
    func an_empty_quantity_is_reported_for_its_original_row() {
        var generated = recipe
        generated.ingredients.append(.init(ingredient: "Oil", amount: " \n "))

        #expect(RecipeGenerationOperations.draftIssues(in: generated) == [.missingIngredientAmount(row: 2)])
    }

    @Test
    func empty_names_and_marker_only_steps_are_observable_omissions() {
        var generated = recipe
        generated.name = " \n "
        generated.ingredients = [.init(ingredient: " ", amount: "300 g")]
        generated.steps = ["1. ", "- "]

        #expect(RecipeGenerationOperations.draftIssues(in: generated) == [
            .missingName, .missingIngredientName(row: 1), .missingSteps
        ])
    }

    @Test
    func a_targeted_repair_receives_the_original_draft_and_specific_finding() async throws {
        var generated = recipe
        generated.ingredients[0].amount = ""
        var repairs = 0
        let draft = try await RecipeGenerationOperations.validatedDraft(from: generated) { original, issues in
            repairs += 1
            #expect(original == generated)
            #expect(issues == [.missingIngredientAmount(row: 1)])
            return recipe
        }

        #expect(draft == recipe)
        #expect(repairs == 1)
    }

    @Test
    func a_repair_that_remains_incomplete_is_rejected_without_a_loop() async throws {
        var generated = recipe
        generated.ingredients[0].amount = ""
        var repairs = 0
        let draft = try await RecipeGenerationOperations.validatedDraft(from: generated) { original, _ in
            repairs += 1
            return original
        }

        #expect(draft == nil)
        #expect(repairs == 1)
    }

    @Test
    func a_service_error_during_repair_is_not_retried() async {
        var generated = recipe
        generated.ingredients[0].amount = ""
        var repairs = 0
        do {
            _ = try await RecipeGenerationOperations.validatedDraft(from: generated) { _, _ in
                repairs += 1
                throw RecipeGenerationError.networkFailure
            }
            Issue.record("The repair failure must be surfaced.")
        } catch {
            #expect(error as? RecipeGenerationError == .networkFailure)
        }
        #expect(repairs == 1)
    }

    @Test(arguments: [false, true])
    func cancellation_discards_a_late_repair_or_service_error(returnsError: Bool) async {
        var generated = recipe
        generated.ingredients[0].amount = ""
        let operation = Task {
            try await RecipeGenerationOperations.validatedDraft(from: generated) { _, _ in
                withUnsafeCurrentTask { $0?.cancel() }
                if returnsError {
                    throw RecipeGenerationError.networkFailure
                }
                return recipe
            }
        }
        do {
            _ = try await operation.value
            Issue.record("A cancelled repair must not reach the form.")
        } catch {
            #expect(error is CancellationError)
        }
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
