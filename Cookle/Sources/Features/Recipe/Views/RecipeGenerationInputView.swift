import CookleLibrary
import SwiftUI

@available(iOS 26.0, *)
struct RecipeGenerationInputView: View {
    private enum Layout {
        static let formLineCount = 3...8
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
    @State private var isSearchPresented = false
    @State private var isEditingRequest = false
    // Search clears its UI text when dismissed; the recipe request must survive closing.
    @State private var searchText = ""

    var body: some View {
        Group {
            if style.usesSearchField {
                searchInput
            } else {
                inputContent
            }
        }
        .toolbar {
            if style == .form, isRequestFocused {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        isRequestFocused = false
                    }
                }
            }
        }
        .sheet(isPresented: $isEditingRequest) {
            NavigationStack {
                TextEditor(text: $text)
                    .padding()
                    .navigationTitle("Recipe Request")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
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
        case .searchTab, .searchToolbar:
            searchRequestOverview
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
        case .requestStack:
            List {
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
    var searchInput: some View {
        inputContent
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                placement: style == .searchToolbar ? .navigationBarDrawer(displayMode: .always) : .automatic,
                prompt: Text("What would you like to cook?")
            )
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .task {
                searchText = text
            }
            .onChange(of: isSearchPresented) {
                if isSearchPresented {
                    searchText = text
                }
            }
            .onChange(of: searchText) {
                if isSearchPresented, !isLoading {
                    text = searchText
                }
            }
            .onChange(of: text) {
                if isSearchPresented, searchText != text {
                    searchText = text
                }
            }
            .onSubmit(of: .search) {
                if canSubmit {
                    createDraft()
                }
            }
            .disabled(isLoading)
    }

    var searchRequestOverview: some View {
        Form {
            if !text.isEmpty {
                Section("Recipe Request") {
                    Text(verbatim: text)
                        .textSelection(.enabled)
                }
            }
            Section {
                processingControls
            } footer: {
                introduction
            }
        }
        .scrollDismissesKeyboard(.interactively)
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
