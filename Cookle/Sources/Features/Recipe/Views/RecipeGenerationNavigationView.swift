import SwiftUI

@available(iOS 26.0, *)
struct RecipeGenerationNavigationView: View {
    private let model: RecipeFormModel

    @State private var request = ""
    @State private var preference = ""
    @State private var isLoading = false

    private var hasPendingRequest: Bool {
        !preference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            InferRecipeFormView(
                model: model,
                source: .generation,
                generationInputStyle: .preferences,
                generationRequest: $request,
                generationLoading: $isLoading,
                hasPendingGenerationRequest: hasPendingRequest
            )
            .safeAreaBar(edge: .bottom) {
                RecipePreferenceInputView(
                    text: $preference,
                    request: $request,
                    isLoading: isLoading
                )
            }
        }
    }

    init(model: RecipeFormModel) {
        self.model = model
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    if #available(iOS 26.0, *) {
        RecipeGenerationNavigationView(model: .init(type: .create))
    }
}
