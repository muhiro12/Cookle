import CookleLibrary
import Foundation
import Testing

struct RecipeInferenceApplicationTests {
    @Test
    func a_blank_form_with_placeholder_rows_needs_no_review() {
        let blankInput = input(
            ingredients: [
                .init(ingredient: " ", amount: "")
            ],
            steps: ["", "\n"],
            categories: [""]
        )

        #expect(RecipeFormOperations.inferenceReplacesEnteredValues(in: blankInput) == false)
    }

    @Test
    func photos_alone_need_no_review_because_inference_keeps_them() {
        let photoOnlyInput = input(
            photos: [samplePhoto]
        )

        #expect(RecipeFormOperations.inferenceReplacesEnteredValues(in: photoOnlyInput) == false)
    }

    @Test(
        arguments: [
            TestInput.name,
            .servingSize,
            .cookingTime,
            .ingredientName,
            .ingredientAmount,
            .step,
            .category,
            .note
        ]
    )
    func any_entered_value_needs_review(field: TestInput) {
        #expect(RecipeFormOperations.inferenceReplacesEnteredValues(in: field.input))
    }

    @Test
    func applying_keeps_photos_and_does_not_invent_unknown_values() {
        let application = RecipeFormOperations.applyInference(
            inference(
                servingSize: .zero,
                cookingTime: .zero
            ),
            sourceURL: nil,
            to: input(
                name: "Typed",
                photos: [samplePhoto],
                servingSize: "4"
            )
        )
        let appliedInput = application.appliedInput

        #expect(appliedInput.name == "Curry")
        #expect(appliedInput.photos.map(\.data) == [samplePhoto.data])
        #expect(appliedInput.servingSize.isEmpty)
        #expect(appliedInput.cookingTime.isEmpty)
        #expect(appliedInput.ingredients.map(\.ingredient) == ["Rice", ""])
        #expect(appliedInput.steps == ["Cook", ""])
        #expect(appliedInput.categories == ["Dinner", ""])
        #expect(appliedInput.note == "Mild")
    }

    @Test
    func applying_appends_the_source_address_to_the_note() throws {
        let sourceURL = try #require(URL(string: "https://example.com/curry"))

        let application = RecipeFormOperations.applyInference(
            inference(),
            sourceURL: sourceURL,
            to: input()
        )

        #expect(application.appliedInput.note == "Mild\n\nhttps://example.com/curry")
    }

    @Test
    func undo_restores_the_full_previous_input_including_photos() {
        let previousInput = input(
            name: "Typed",
            photos: [samplePhoto],
            servingSize: "4",
            ingredients: [
                .init(ingredient: "Salt", amount: "1 pinch")
            ],
            note: "Mine"
        )

        let application = RecipeFormOperations.applyInference(
            inference(),
            sourceURL: nil,
            to: previousInput
        )

        #expect(application.previousInput.name == "Typed")
        #expect(application.previousInput.photos.map(\.data) == [samplePhoto.data])
        #expect(application.previousInput.servingSize == "4")
        #expect(application.previousInput.ingredients.map(\.ingredient) == ["Salt"])
        #expect(application.previousInput.note == "Mine")
    }

    @Test
    func unedited_applied_input_has_no_later_edits() {
        let application = RecipeFormOperations.applyInference(
            inference(),
            sourceURL: nil,
            to: input()
        )
        var currentInput = application.appliedInput
        currentInput.steps.append("")

        #expect(application.hasEdits(in: application.appliedInput) == false)
        #expect(application.hasEdits(in: currentInput) == false)
    }

    @Test
    func text_or_photo_changes_after_applying_are_later_edits() {
        let application = RecipeFormOperations.applyInference(
            inference(),
            sourceURL: nil,
            to: input()
        )
        var editedName = application.appliedInput
        editedName.name = "Curry and rice"
        var addedPhoto = application.appliedInput
        addedPhoto.photos.append(samplePhoto)

        #expect(application.hasEdits(in: editedName))
        #expect(application.hasEdits(in: addedPhoto))
    }

    @Test
    func a_repeated_application_undoes_only_to_the_input_before_it() {
        let first = RecipeFormOperations.applyInference(
            inference(name: "First"),
            sourceURL: nil,
            to: input(name: "Typed")
        )
        var editedAfterFirst = first.appliedInput
        editedAfterFirst.note = "Edited after first"

        let second = RecipeFormOperations.applyInference(
            inference(name: "Second"),
            sourceURL: nil,
            to: editedAfterFirst
        )

        #expect(second.previousInput.name == "First")
        #expect(second.previousInput.note == "Edited after first")
        #expect(second.appliedInput.name == "Second")
    }
}

extension RecipeInferenceApplicationTests {
    enum TestInput: CaseIterable, Sendable {
        case name
        case servingSize
        case cookingTime
        case ingredientName
        case ingredientAmount
        case step
        case category
        case note

        var input: RecipeFormInput {
            switch self {
            case .name:
                RecipeInferenceApplicationTests.input(name: "Typed")
            case .servingSize:
                RecipeInferenceApplicationTests.input(servingSize: "2")
            case .cookingTime:
                RecipeInferenceApplicationTests.input(cookingTime: "15")
            case .ingredientName:
                RecipeInferenceApplicationTests.input(
                    ingredients: [
                        .init(ingredient: "Salt", amount: "")
                    ]
                )
            case .ingredientAmount:
                RecipeInferenceApplicationTests.input(
                    ingredients: [
                        .init(ingredient: "", amount: "1 pinch")
                    ]
                )
            case .step:
                RecipeInferenceApplicationTests.input(steps: ["Boil"])
            case .category:
                RecipeInferenceApplicationTests.input(categories: ["Dinner"])
            case .note:
                RecipeInferenceApplicationTests.input(note: "Mine")
            }
        }
    }
}

private extension RecipeInferenceApplicationTests {
    var samplePhoto: PhotoData {
        .init(
            data: Data("photo".utf8),
            source: .photosPicker
        )
    }

    static func input(
        name: String = "",
        photos: [PhotoData] = [],
        servingSize: String = "",
        cookingTime: String = "",
        ingredients: [RecipeFormIngredientInput] = [],
        steps: [String] = [],
        categories: [String] = [],
        note: String = ""
    ) -> RecipeFormInput {
        .init(
            name: name,
            photos: photos,
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredients: ingredients,
            steps: steps,
            categories: categories,
            note: note
        )
    }

    func input(
        name: String = "",
        photos: [PhotoData] = [],
        servingSize: String = "",
        cookingTime: String = "",
        ingredients: [RecipeFormIngredientInput] = [],
        steps: [String] = [],
        categories: [String] = [],
        note: String = ""
    ) -> RecipeFormInput {
        Self.input(
            name: name,
            photos: photos,
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredients: ingredients,
            steps: steps,
            categories: categories,
            note: note
        )
    }

    func inference(
        name: String = "Curry",
        servingSize: Int = 2,
        cookingTime: Int = 30
    ) -> RecipeInferenceResult {
        .init(
            name: name,
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredients: [
                .init(ingredient: "Rice", amount: "1 cup")
            ],
            steps: ["Cook"],
            categories: ["Dinner"],
            note: "Mild"
        )
    }
}
