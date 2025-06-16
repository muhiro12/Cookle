import AppIntents
import FoundationModels
import SwiftUI
import SwiftUtilities

struct GenerateRecipeIntent: AppIntent, IntentPerformer {
    static var title: LocalizedStringResource { .init("Generate Recipe") }

    @Parameter(title: "Prompt")
    private var prompt: String

    typealias Input = String
    typealias Output = Recipe

    @MainActor
    static func perform(_ input: Input) async throws -> Output {
        let session = LanguageModelSession()
        let generated = try await session.respond(
            to: "Create a cooking recipe that matches the following request:\n\(input)",
            generating: GeneratedRecipe.self
        ).content

        let context = CookleIntents.context
        return Recipe.create(
            context: context,
            name: generated.name,
            photos: [],
            servingSize: .zero,
            cookingTime: .zero,
            ingredients: generated.ingredients.enumerated().map { index, element in
                .create(
                    context: context,
                    ingredient: element,
                    amount: "",
                    order: index + 1
                )
            },
            steps: generated.steps,
            categories: [],
            note: ""
        )
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let recipe = try await Self.perform(prompt)
        return .result(dialog: .init(stringLiteral: recipe.name)) {
            CookleIntents.cookleView {
                VStack(alignment: .leading) {
                    RecipeIngredientsSection()
                    Divider()
                    RecipeStepsSection()
                }
                .environment(recipe)
            }
        }
    }
}
