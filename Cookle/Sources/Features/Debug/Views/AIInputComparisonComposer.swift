#if DEBUG
import SwiftUI

/// Uses real preference and draft handling while comparing native input placements.
@available(iOS 26, *)
struct AIInputComparisonComposer: View {
    private enum Layout {
        static let contentPadding = 12.0
        static let bottomSpacing = 8.0
        static let inputLineCount = 1...3
    }

    let layout: AIInputComparisonLayout
    @Binding var request: String
    @Binding var preference: String
    @Binding var isLoading: Bool

    @Environment(RecipeFormPresenter.self)
    private var presenter

    @State private var model = RecipeFormModel(type: .create)
    @FocusState private var isFocused: Bool

    private var canAdd: Bool {
        !isLoading && !preference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        inputContent
            .toolbar {
                if layout == .sidebarToolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        preferenceField
                        addButton
                    }
                }
            }
    }

    @ViewBuilder private var inputContent: some View {
        if layout == .sidebarToolbar {
            generationForm
        } else {
            generationForm
                .safeAreaBar(edge: .bottom) {
                    HStack(alignment: .bottom) {
                        preferenceField
                        addButton
                    }
                    .padding(Layout.contentPadding)
                    .glassEffect(.regular)
                    .padding(.horizontal)
                    .padding(.bottom, Layout.bottomSpacing)
                }
        }
    }

    private var generationForm: some View {
        InferRecipeFormView(
            model: model,
            source: .generation,
            generationInputStyle: .preferences,
            generationRequest: $request,
            generationLoading: $isLoading,
            hasPendingGenerationRequest: !preference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onInferenceApplied: presentDraft
        )
    }

    private var preferenceField: some View {
        TextField("Add a preference", text: $preference, axis: .vertical)
            .lineLimit(Layout.inputLineCount)
            .frame(maxWidth: .infinity)
            .focused($isFocused)
            .disabled(isLoading)
            .accessibilityIdentifier("comparisonPreferenceInput")
    }

    private var addButton: some View {
        Button("Add Preference", systemImage: "plus.circle.fill") {
            let value = preference.trimmingCharacters(in: .whitespacesAndNewlines)
            request = [request, value].filter { !$0.isEmpty }.joined(separator: "\n")
            preference = ""
            isFocused = true
        }
        .labelStyle(.iconOnly)
        .disabled(!canAdd)
        .accessibilityIdentifier("comparisonAddPreference")
    }
}

@available(iOS 26, *)
private extension AIInputComparisonComposer {
    func presentDraft() {
        presenter.present(draft: model)
        model = .init(type: .create)
    }
}
#endif
