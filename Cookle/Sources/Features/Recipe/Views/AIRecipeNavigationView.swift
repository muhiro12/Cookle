import SwiftUI

struct AIRecipeNavigationView: View {
    @Binding var request: String
    @Binding var isLoading: Bool
    let hasPendingRequest: Bool

    @Environment(RecipeFormPresenter.self)
    private var presenter

    @State private var model = RecipeFormModel(type: .create)

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
