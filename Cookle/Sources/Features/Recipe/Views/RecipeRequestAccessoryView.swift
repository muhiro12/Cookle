import SwiftUI

/// A system tab accessory opens a standard sheet for keyboard-safe text entry.
@available(iOS 26.0, *)
struct RecipeRequestAccessoryView: View {
    private enum Layout {
        static let minimumButtonHeight = 44.0
        static let inputLineCount = 2...5
    }

    @Binding var text: String
    @Binding var request: String
    let isLoading: Bool

    @State private var isInputPresented = false
    @FocusState private var isFocused: Bool
    @Namespace private var transition

    private var canAdd: Bool {
        !isLoading && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Button {
            isInputPresented = true
        } label: {
            Label("Add Preference", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity, minHeight: Layout.minimumButtonHeight, alignment: .leading)
                .contentShape(.rect)
        }
        .padding(.horizontal)
        .accessibilityIdentifier("recipePreferenceEntry")
        .matchedTransitionSource(id: "recipePreference", in: transition)
        .disabled(isLoading)
        .sheet(
            isPresented: $isInputPresented,
            onDismiss: {
                text = ""
            },
            content: {
                inputSheet
            }
        )
    }

    private var inputSheet: some View {
        NavigationStack {
            Form {
                TextField(
                    "Add a preference",
                    text: $text,
                    axis: .vertical
                )
                .lineLimit(Layout.inputLineCount)
                .accessibilityIdentifier("recipePreferenceInput")
                .focused($isFocused)
            }
            .navigationTitle("Add Preference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isInputPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Preference", action: addPreference)
                        .disabled(!canAdd)
                }
            }
            .task {
                isFocused = true
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .navigationTransition(.zoom(sourceID: "recipePreference", in: transition))
    }
}

@available(iOS 26.0, *)
private extension RecipeRequestAccessoryView {
    func addPreference() {
        guard canAdd else {
            return
        }
        let preference = text.trimmingCharacters(in: .whitespacesAndNewlines)
        request = [request, preference].filter { !$0.isEmpty }.joined(separator: "\n")
        text = ""
        isInputPresented = false
    }
}
