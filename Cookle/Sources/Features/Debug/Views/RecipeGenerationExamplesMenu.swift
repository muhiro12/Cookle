#if DEBUG
import SwiftUI

/// Inserts requests without running the model, for keyboard and long-text review.
struct RecipeGenerationExamplesMenu: View {
    @Binding var text: String

    var body: some View {
        Menu {
            Button("Short Example") {
                text = String(localized: "A simple tofu and mushroom dinner for two, using one frying pan.")
            }
            Button("Long Example") {
                text = String(localized: """
                    Dinner for two, ready in 20 minutes, using tofu and shimeji mushrooms.
                    Use one frying pan. Avoid eggs, dairy, and spicy seasoning.
                    Use common pantry seasonings. Include preparation, heat levels, cooking times, and doneness cues.
                    Write the recipe in Japanese.
                    """)
            }
            Button("Clear Request") {
                text = ""
            }
        } label: {
            Label("Input Examples", systemImage: "text.badge.plus")
        }
        .accessibilityIdentifier("recipeGenerationExamples")
    }
}
#endif
