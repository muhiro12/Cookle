import SwiftUI

@available(iOS 26.0, *)
struct RecipePreferenceInputView: View {
    private enum Layout {
        static let controlSpacing = 12.0
        static let horizontalInputPadding = 16.0
        static let verticalInputPadding = 12.0
        static let minimumInputHeight = 48.0
        static let bottomSpacing = 8.0
        static let inputLineCount = 1...3
    }

    @Binding var text: String
    @Binding var request: String
    let isLoading: Bool

    @FocusState private var isFocused: Bool

    private var canAdd: Bool {
        !isLoading && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        // Keep the field and action separate even when their glass is rendered together.
        GlassEffectContainer(spacing: .zero) {
            HStack(alignment: .bottom, spacing: Layout.controlSpacing) {
                TextField("Add a preference", text: $text, axis: .vertical)
                    .lineLimit(Layout.inputLineCount)
                    .focused($isFocused)
                    .padding(.horizontal, Layout.horizontalInputPadding)
                    .padding(.vertical, Layout.verticalInputPadding)
                    .frame(maxWidth: .infinity, minHeight: Layout.minimumInputHeight)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .disabled(isLoading)
                    .accessibilityIdentifier("recipePreferenceInput")

                Button("Add Preference", systemImage: "plus", action: addPreference)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .disabled(!canAdd)
                    .accessibilityIdentifier("recipePreferenceAdd")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, Layout.bottomSpacing)
        .toolbar {
            if isFocused {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hide Keyboard", systemImage: "keyboard.chevron.compact.down") {
                        isFocused = false
                    }
                    .accessibilityIdentifier("recipePreferenceDismissKeyboard")
                }
            }
        }
        .onChange(of: isLoading) {
            if isLoading {
                isFocused = false
            }
        }
    }
}

@available(iOS 26.0, *)
private extension RecipePreferenceInputView {
    func addPreference() {
        guard canAdd else {
            return
        }
        let preference = text.trimmingCharacters(in: .whitespacesAndNewlines)
        request = [request, preference].filter { !$0.isEmpty }.joined(separator: "\n")
        text = ""
        isFocused = true
    }
}
