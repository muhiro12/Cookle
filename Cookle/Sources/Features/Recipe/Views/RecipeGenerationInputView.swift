import CookleLibrary
import SwiftUI

@available(iOS 26.0, *)
struct RecipeGenerationInputView: View {
    private enum Layout {
        static let composerLineCount = 1...3
        static let formLineCount = 3...8
        static let minimumInputHeight = 44.0
    }

    let style: RecipeGenerationInputStyle
    @Binding var text: String
    @Binding var onDeviceOnly: Bool
    let status: RecipeGenerationStatus?
    let isLoading: Bool
    let requestsFocus: Bool
    let canSubmit: Bool
    let createDraft: () -> Void

    @FocusState private var isRequestFocused: Bool

    var body: some View {
        inputContent
            .toolbar {
                if style != .editor, isRequestFocused {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            isRequestFocused = false
                        }
                    }
                }
            }
    }

    @ViewBuilder private var inputContent: some View {
        switch style {
        case .editor:
            VStack(alignment: .leading) {
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
        case .bottomComposer:
            ScrollView {
                VStack(alignment: .leading) {
                    introduction
                    processingControls
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaBar(edge: .bottom) {
                HStack(alignment: .bottom) {
                    requestField
                        .lineLimit(Layout.composerLineCount)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: Layout.minimumInputHeight)
                    Button(action: createDraft) {
                        Label("Create Draft", systemImage: "arrow.up")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canSubmit)
                }
                .padding()
            }
        case .form:
            Form {
                Section {
                    requestField
                        .lineLimit(Layout.formLineCount)
                } header: {
                    Text("Recipe Request")
                } footer: {
                    introduction
                }
                Section {
                    processingControls
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

@available(iOS 26.0, *)
private extension RecipeGenerationInputView {
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
            onDeviceOnly: $onDeviceOnly,
            status: status,
            isLoading: isLoading
        )
    }

    var requestField: some View {
        TextField(
            "Recipe Request",
            text: $text,
            prompt: Text("What would you like to cook?"),
            axis: .vertical
        )
        .accessibilityLabel(Text("Recipe Request"))
        .accessibilityIdentifier("recipeGenerationRequest")
        .focused($isRequestFocused)
        .disabled(isLoading)
    }
}
