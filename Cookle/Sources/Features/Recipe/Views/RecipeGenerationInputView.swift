import CookleLibrary
import SwiftUI

@available(iOS 26.0, *)
struct RecipeGenerationInputView: View {
    let style: RecipeGenerationInputStyle
    @Binding var text: String
    let isLoading: Bool
    let requestsFocus: Bool

    @State private var isEditingRequest = false

    var body: some View {
        inputContent
            .sheet(isPresented: $isEditingRequest) {
                NavigationStack {
                    TextEditor(text: $text)
                        .padding()
                        .navigationTitle("Recipe Request")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                DoneButton {
                                    isEditingRequest = false
                                }
                            }
                        }
                }
            }
    }

    @ViewBuilder private var inputContent: some View {
        switch style {
        case .editor:
            VStack(alignment: .leading) {
                draftNotice
                introduction
                processingControls
                RecipeRequestEditorView(
                    text: $text,
                    source: .generation,
                    isLoading: isLoading,
                    requestsFocus: requestsFocus
                )
            }
            .padding()
        case .preferences:
            List {
                Section {
                    draftNotice
                }
                RecipeRequestStackSection(text: $text, isLoading: isLoading) {
                    isEditingRequest = true
                }
                Section {
                    processingControls
                } footer: {
                    introduction
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

@available(iOS 26.0, *)
private extension RecipeGenerationInputView {
    var draftNotice: some View {
        VStack(alignment: .leading) {
            Label("AI Recipe Draft", systemImage: "exclamationmark.bubble")
                .font(.headline)
            Text(
                """
                AI-generated drafts may contain errors or omissions. Before cooking, review the \
                ingredients, quantities, steps, heating, and storage instructions. Generation may \
                fail even when PCC is shown as available.
                """
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    var introduction: some View {
        Text(
            """
            Describe a dish, ingredients, or preferences. AI creates a starting point you can edit \
            and improve after cooking.
            """
        )
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    var processingControls: some View {
        RecipeGenerationControlsView(
            isLoading: isLoading
        )
    }
}
