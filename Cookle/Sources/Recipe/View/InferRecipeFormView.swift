import AppIntents
import SwiftUI

@available(iOS 26.0, *)
struct InferRecipeFormView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var text: String
    private let onComplete: (InferredRecipeForm) -> Void
    private let placeholder: LocalizedStringKey = """
        Spaghetti Carbonara for 2 people.
        Ingredients: Spaghetti 200g, Eggs 2, Pancetta 100g.
        Cook spaghetti. Fry pancetta. Mix eggs and cheese. Combine all.
        """

    init(text: Binding<String>, onComplete: @escaping (InferredRecipeForm) -> Void) {
        self._text = text
        self.onComplete = onComplete
    }

    var body: some View {
        TextEditor(text: $text)
            .overlay(alignment: .topLeading) {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(.placeholder)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .allowsHitTesting(false)
                    .hidden(text.isNotEmpty)
            }
            .padding()
            .scrollContentBackground(.hidden)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 8))
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("Recipe Text"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        text = ""
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if let inference = try? await InferRecipeIntent.inference(text) {
                                onComplete(inference)
                                text = ""
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Done")
                    }
                }
            }
            .font(nil)
    }
}
