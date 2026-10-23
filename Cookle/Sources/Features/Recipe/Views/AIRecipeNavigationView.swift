import SwiftUI

struct AIRecipeNavigationView: View {
    @Binding var request: String
    @Binding var preference: String

    @Environment(RecipeFormPresenter.self)
    private var presenter

    @State private var model = RecipeFormModel(type: .create)
    @State private var isLoading = false

    private var hasPendingRequest: Bool {
        !preference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            if #available(iOS 26.0, *) {
                InferRecipeFormView(
                    model: model,
                    source: .generation,
                    generationInputStyle: .preferences,
                    generationRequest: $request,
                    generationLoading: $isLoading,
                    hasPendingGenerationRequest: hasPendingRequest,
                    onInferenceApplied: presentDraft
                )
                .safeAreaBar(edge: .bottom) {
                    RecipePreferenceInputView(
                        text: $preference,
                        request: $request,
                        isLoading: isLoading
                    )
                }
            } else {
                ContentUnavailableView {
                    Label("Create with AI", systemImage: "sparkles")
                } description: {
                    Text("Apple Intelligence is not available right now.")
                }
            }
        }
    }
}

private extension AIRecipeNavigationView {
    func presentDraft() {
        presenter.present(draft: model)
        model = .init(type: .create)
    }
}
