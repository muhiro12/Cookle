import SwiftUI

struct AddMultipleTextsView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var texts: [String]

    @State private var text: String

    private let title: LocalizedStringKey
    private let placeholder: LocalizedStringKey

    init(texts: Binding<[String]>, title: LocalizedStringKey, placeholder: LocalizedStringKey) {
        self._texts = texts
        self.text = texts.wrappedValue.joined(separator: "\n")
        self.title = title
        self.placeholder = placeholder
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
            .navigationTitle(title)
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
                        texts = text.split(separator: "\n", omittingEmptySubsequences: false).map {
                            String($0)
                        }
                        text = ""
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
            .font(nil)
    }
}

#Preview {
    AddMultipleTextsNavigationView(
        texts: .constant([]),
        title: "Ingredients",
        placeholder: """
                     Boil water in a large pot and add salt.
                     Cook the spaghetti until al dente.
                     In a separate pan, cook the pancetta until crispy.
                     Beat the eggs in a bowl and mix with grated Parmesan cheese.
                     Drain the spaghetti and mix with pancetta and the egg mixture.
                     Season with black pepper and serve immediately.
                     """
    )
}
