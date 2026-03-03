import FoundationModels
import SwiftData
import SwiftUI

@available(iOS 26.0, *)
private struct IngredientGenerationAlertContent: Identifiable {
    let id = UUID()
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}

@available(iOS 26.0, *)
struct GenerateRecipeFromIngredientsView: View {
    @Environment(\.dismiss)
    private var dismiss

    @Query(Ingredient.descriptor(.all))
    private var allIngredients: [Ingredient]

    @Binding private var name: String
    @Binding private var servingSize: String
    @Binding private var cookingTime: String
    @Binding private var ingredients: [RecipeFormIngredient]
    @Binding private var steps: [String]
    @Binding private var categories: [String]
    @Binding private var note: String

    @State private var selectedIngredientIDs = Set<PersistentIdentifier>()
    @State private var manualIngredients = [String]()
    @State private var pendingIngredient = ""
    @State private var additionalInstructions = ""
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var alertContent: IngredientGenerationAlertContent?

    private let preferencePlaceholder: LocalizedStringKey = """
        Quick dinner, high protein, not spicy.
        """

    private var filteredIngredients: [Ingredient] {
        allIngredients.filter { ingredient in
            searchText.isEmpty || ingredient.value.normalizedContains(searchText)
        }
    }

    private var selectedExistingIngredients: [Ingredient] {
        allIngredients
            .filter { ingredient in
                selectedIngredientIDs.contains(ingredient.persistentModelID)
            }
            .sorted { lhs, rhs in
                lhs.value.localizedStandardCompare(rhs.value) == .orderedAscending
            }
    }

    private var selectedIngredientValues: [String] {
        selectedExistingIngredients.map(\.value) + manualIngredients
    }

    private var trimmedPendingIngredient: String {
        pendingIngredient.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAddPendingIngredient: Bool {
        trimmedPendingIngredient.isNotEmpty
            && !selectedIngredientValues.contains { ingredient in
                normalizedIngredientKey(ingredient) == normalizedIngredientKey(trimmedPendingIngredient)
            }
    }

    private var modelAvailability: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }

    private var isModelAvailable: Bool {
        if case .available = modelAvailability {
            return true
        }
        return false
    }

    private var isGenerateDisabled: Bool {
        isLoading || selectedIngredientValues.isEmpty || !isModelAvailable
    }

    var body: some View {
        Form {
            Section {
                if selectedIngredientValues.isEmpty {
                    Text("No ingredients selected yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selectedExistingIngredients) { ingredient in
                        Button {
                            toggleIngredientSelection(ingredient)
                        } label: {
                            HStack {
                                Text(ingredient.value)
                                Spacer()
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(manualIngredients, id: \.self) { ingredient in
                        Button {
                            removeManualIngredient(ingredient)
                        } label: {
                            HStack {
                                Text(ingredient)
                                Spacer()
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Selected Ingredients")
            } footer: {
                Text("Generated recipes can only use the selected ingredients.")
            }

            Section {
                HStack {
                    TextField("Ingredient", text: $pendingIngredient)
                        .onSubmit {
                            addManualIngredient()
                        }

                    Button {
                        addManualIngredient()
                    } label: {
                        Text("Add")
                    }
                    .disabled(!canAddPendingIngredient)
                }
            } header: {
                Text("Add Ingredient")
            }

            Section {
                if filteredIngredients.isEmpty {
                    Text("No matching ingredients.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredIngredients) { ingredient in
                        Button {
                            toggleIngredientSelection(ingredient)
                        } label: {
                            HStack {
                                Text(ingredient.value)
                                Spacer()
                                if selectedIngredientIDs.contains(ingredient.persistentModelID) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Ingredients")
            }

            Section {
                TextEditor(text: $additionalInstructions)
                    .frame(minHeight: 120)
                    .overlay(alignment: .topLeading) {
                        Text(preferencePlaceholder)
                            .font(.body)
                            .foregroundStyle(.placeholder)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 6)
                            .allowsHitTesting(false)
                            .hidden(additionalInstructions.isNotEmpty)
                    }
            } header: {
                Text("Preferences")
            } footer: {
                if case .unavailable(let reason) = modelAvailability {
                    Text(modelAvailabilityMessage(reason))
                }
            }
        }
        .navigationTitle(Text("Generate Recipe From Ingredients"))
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    isLoading = true
                    Task {
                        await generateRecipe()
                    }
                } label: {
                    Text("Generate")
                }
                .disabled(isGenerateDisabled)
            }
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @MainActor
    private func generateRecipe() async {
        defer {
            isLoading = false
        }

        do {
            let inference = try await RecipeService.generateFromIngredients(
                request: .init(
                    availableIngredients: selectedIngredientValues,
                    additionalInstructions: additionalInstructions
                )
            )
            let generatedRecipe = RecipeFormGeneratedRecipe(inference: inference)
            name = generatedRecipe.name
            servingSize = generatedRecipe.servingSize
            cookingTime = generatedRecipe.cookingTime
            ingredients = generatedRecipe.ingredients
            steps = generatedRecipe.steps
            categories = generatedRecipe.categories
            note = generatedRecipe.note
            dismiss()
        } catch let error as IngredientRecipeGenerationError {
            alertContent = alertContent(for: error)
        } catch {
            alertContent = .init(
                title: "Couldn't Generate Recipe",
                message: "Please try again."
            )
        }
    }

    private func addManualIngredient() {
        guard canAddPendingIngredient else {
            return
        }

        manualIngredients.append(trimmedPendingIngredient)
        pendingIngredient = ""
    }

    private func removeManualIngredient(_ ingredient: String) {
        manualIngredients.removeAll { manualIngredient in
            manualIngredient == ingredient
        }
    }

    private func toggleIngredientSelection(_ ingredient: Ingredient) {
        if selectedIngredientIDs.contains(ingredient.persistentModelID) {
            selectedIngredientIDs.remove(ingredient.persistentModelID)
        } else {
            selectedIngredientIDs.insert(ingredient.persistentModelID)
        }
    }

    private func alertContent(
        for error: IngredientRecipeGenerationError
    ) -> IngredientGenerationAlertContent {
        switch error {
        case .emptyIngredients:
            .init(
                title: "Couldn't Generate Recipe",
                message: "Add at least one ingredient before generating."
            )
        case .modelUnavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                .init(
                    title: "Couldn't Generate Recipe",
                    message: "This device does not support on-device recipe generation."
                )
            case .appleIntelligenceNotEnabled:
                .init(
                    title: "Couldn't Generate Recipe",
                    message: "Turn on Apple Intelligence to generate recipes on-device."
                )
            case .modelNotReady:
                .init(
                    title: "Couldn't Generate Recipe",
                    message: "The on-device model is still preparing. Try again later."
                )
            case .none:
                .init(
                    title: "Couldn't Generate Recipe",
                    message: "The on-device model is unavailable right now."
                )
            case .some:
                .init(
                    title: "Couldn't Generate Recipe",
                    message: "The on-device model is unavailable right now."
                )
            }
        case .invalidResponse:
            .init(
                title: "Couldn't Generate Recipe",
                message: "The generated recipe was incomplete. Try changing the selected ingredients or preferences."
            )
        case .disallowedIngredients:
            .init(
                title: "Couldn't Generate Recipe",
                message: "The generated recipe used ingredients outside your selection. Try again with a different ingredient set."
            )
        }
    }

    private func modelAvailabilityMessage(
        _ reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> LocalizedStringKey {
        switch reason {
        case .deviceNotEligible:
            "This device does not support on-device recipe generation."
        case .appleIntelligenceNotEnabled:
            "Turn on Apple Intelligence to generate recipes on-device."
        case .modelNotReady:
            "The on-device model is still preparing. Try again later."
        @unknown default:
            "The on-device model is unavailable right now."
        }
    }

    private func normalizedIngredientKey(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let halfwidthValue = trimmedValue.applyingTransform(
            .fullwidthToHalfwidth,
            reverse: false
        ) ?? trimmedValue
        let katakanaValue = halfwidthValue.applyingTransform(
            .hiraganaToKatakana,
            reverse: false
        ) ?? halfwidthValue

        return katakanaValue.folding(
            options: [
                .caseInsensitive,
                .diacriticInsensitive,
                .widthInsensitive
            ],
            locale: .current
        )
    }

    init(
        name: Binding<String>,
        servingSize: Binding<String>,
        cookingTime: Binding<String>,
        ingredients: Binding<[RecipeFormIngredient]>,
        steps: Binding<[String]>,
        categories: Binding<[String]>,
        note: Binding<String>
    ) {
        self._name = name
        self._servingSize = servingSize
        self._cookingTime = cookingTime
        self._ingredients = ingredients
        self._steps = steps
        self._categories = categories
        self._note = note
    }
}
