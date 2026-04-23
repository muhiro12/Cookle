import SwiftData
import SwiftUI

@available(iOS 26.0, *)
struct RecipeIdeaSuggestionView: View {
    private enum Layout {
        static let rowSpacing = 8.0
    }

    @Environment(\.dismiss)
    private var dismiss

    @Query(Ingredient.descriptor(.all))
    private var ingredients: [Ingredient]

    @State private var selectedIngredientIDs = Set<PersistentIdentifier>()
    @State private var suggestions = [RecipeIdeaSuggestion]()
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        Group {
            if ingredients.isEmpty {
                emptyStateView
            } else {
                suggestionForm
            }
        }
        .navigationTitle(Text("Ingredient Ideas"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .alert(
            Text("Cannot Suggest Ideas"),
            isPresented: isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                errorMessage = .empty
            }
        } message: {
            Text(errorMessage)
        }
    }
}

@available(iOS 26.0, *)
private extension RecipeIdeaSuggestionView {
    var suggestionForm: some View {
        Form {
            ingredientSection
            actionSection
            if suggestions.isNotEmpty {
                suggestionSection
            }
            explanationSection
        }
    }

    var ingredientSection: some View {
        Section {
            ForEach(ingredients) { ingredient in
                Toggle(
                    ingredient.value,
                    isOn: isSelectedBinding(for: ingredient)
                )
            }
        } header: {
            Text("Selected Ingredients")
        } footer: {
            Text("Choose the ingredients you want to build around.")
        }
    }

    var actionSection: some View {
        Section {
            Button {
                generateIdeas()
            } label: {
                HStack {
                    Text("Suggest Ideas")
                    Spacer()
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .disabled(isGenerateDisabled)
        }
    }

    var suggestionSection: some View {
        Section("Ideas") {
            ForEach(suggestions.indices, id: \.self) { index in
                suggestionRow(
                    suggestions[index]
                )
            }
        }
    }

    var explanationSection: some View {
        Section {
            Text("Cookle only suggests directions here. Nothing is saved until you review and create it yourself.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Ingredients Yet", systemImage: "carrot")
        } description: {
            Text("Ingredients appear after you create recipes.")
        } actions: {
            AddRecipeButton()
        }
    }

    var isGenerateDisabled: Bool {
        isLoading || selectedIngredientValues.isEmpty
    }

    var selectedIngredientValues: [String] {
        ingredients.compactMap { ingredient in
            selectedIngredientIDs.contains(
                ingredient.persistentModelID
            ) ? ingredient.value : nil
        }
    }

    var isErrorPresented: Binding<Bool> {
        .init(
            get: {
                errorMessage.isNotEmpty
            },
            set: { isPresented in
                if isPresented == false {
                    errorMessage = .empty
                }
            }
        )
    }

    func isSelectedBinding(
        for ingredient: Ingredient
    ) -> Binding<Bool> {
        .init {
            selectedIngredientIDs.contains(
                ingredient.persistentModelID
            )
        } set: { isSelected in
            if isSelected {
                selectedIngredientIDs.insert(
                    ingredient.persistentModelID
                )
            } else {
                selectedIngredientIDs.remove(
                    ingredient.persistentModelID
                )
            }
        }
    }

    func suggestionRow(
        _ suggestion: RecipeIdeaSuggestion
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            Text(suggestion.title)
                .font(.headline)
            if suggestion.flavorDirection.isNotEmpty {
                Text(suggestion.flavorDirection)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if suggestion.roughApproach.isNotEmpty {
                Text(suggestion.roughApproach)
            }
            if suggestion.coreIngredients.isNotEmpty {
                Text("Uses: \(suggestion.coreIngredients.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    func generateIdeas() {
        guard isLoading == false else {
            return
        }

        isLoading = true
        Task {
            await applyGeneratedIdeas()
        }
    }

    @MainActor
    func applyGeneratedIdeas() async {
        defer {
            isLoading = false
        }

        do {
            suggestions = try await RecipeIdeaSuggestionService.suggest(
                ingredients: selectedIngredientValues
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    if #available(iOS 26.0, *) {
        NavigationStack {
            RecipeIdeaSuggestionView()
        }
    }
}
