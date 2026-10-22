import MHUI
import SwiftUI

/// Shared text editor for generation and the existing text/photo import flow.
struct RecipeRequestEditorView: View {
    @Binding var text: String
    let source: RecipeDraftSource
    let isLoading: Bool
    let requestsFocus: Bool

    @Environment(\.mhDesignMetrics)
    private var designMetrics

    @FocusState private var isTextFocused: Bool

    // Keep a literal so the string catalog extracts and translates the sample.
    private let placeholder: LocalizedStringKey = """
        Spaghetti Carbonara for 2 people.
        Ingredients: Spaghetti 200g, Eggs 2, Pancetta 100g.
        Cook spaghetti. Fry pancetta. Mix eggs and cheese. Combine all.
        """

    var body: some View {
        TextEditor(text: $text)
            .focused($isTextFocused)
            .disabled(isLoading)
            .accessibilityLabel(source == .generation ? Text("Recipe Request") : Text("Recipe Text"))
            .accessibilityValue(Text(verbatim: text))
            .overlay(alignment: .topLeading) {
                placeholderOverlay
            }
            .scrollDismissesKeyboard(.immediately)
            .mhInputChrome(state: isTextFocused ? .focused : .normal)
            .task {
                if requestsFocus {
                    isTextFocused = true
                }
            }
    }
}

private extension RecipeRequestEditorView {
    @ViewBuilder var placeholderOverlay: some View {
        if text.isEmpty {
            Group {
                if source == .generation {
                    Text("A simple tofu and mushroom dinner for two, using one frying pan.")
                } else {
                    Text(placeholder)
                }
            }
            .font(.body)
            .foregroundStyle(.placeholder)
            .padding(
                .vertical,
                RecipeTextEditorLayout.placeholderVerticalPadding(metrics: designMetrics)
            )
            .padding(.horizontal, RecipeTextEditorLayout.placeholderHorizontalPadding)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
