import SwiftUI

@available(iOS 26.0, *)
struct RecipePreferenceFormView: View {
    private enum Layout {
        static let sheetFraction = 0.33
        static let inputLineCount = 2...5
    }

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    @Binding var text: String
    @Binding var request: String
    @FocusState private var isFocused: Bool

    private var canAdd: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var detent: PresentationDetent {
        if dynamicTypeSize.isAccessibilitySize || verticalSizeClass == .compact {
            return .large
        }
        return .fraction(Layout.sheetFraction)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Add a preference", text: $text, axis: .vertical)
                    .lineLimit(Layout.inputLineCount)
                    .accessibilityIdentifier("recipePreferenceInput")
                    .focused($isFocused)
            }
            .navigationTitle("Add Preference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
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
        .presentationDetents([detent])
        .presentationDragIndicator(.visible)
    }
}

@available(iOS 26.0, *)
private extension RecipePreferenceFormView {
    func addPreference() {
        guard canAdd else {
            return
        }
        let preference = text.trimmingCharacters(in: .whitespacesAndNewlines)
        request = [request, preference].filter { !$0.isEmpty }.joined(separator: "\n")
        text = ""
        dismiss()
    }
}
