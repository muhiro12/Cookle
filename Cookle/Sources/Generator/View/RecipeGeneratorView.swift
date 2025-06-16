import SwiftUI
import AppIntents

struct RecipeGeneratorView: View {
    @State private var prompt = ""
    @State private var recipe: Recipe?
    @FocusState private var isFocused: Bool

    var body: some View {
        List {
            Section("Prompt") {
                TextField("Describe your request", text: $prompt)
                    .focused($isFocused)
            }
            Section {
                Button("Generate") {
                    Task {
                        recipe = try? await GenerateRecipeIntent.perform(prompt)
                        isFocused = false
                    }
                }
                .disabled(prompt.isEmpty)
            }
            if let recipe {
                Section("Result") {
                    VStack(alignment: .leading) {
                        Text(recipe.name)
                            .font(.headline)
                        RecipeIngredientsSection()
                        Divider()
                        RecipeStepsSection()
                    }
                    .environment(recipe)
                }
            }
        }
        .navigationTitle(Text("Generate Recipe"))
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            RecipeGeneratorView()
        }
    }
}
