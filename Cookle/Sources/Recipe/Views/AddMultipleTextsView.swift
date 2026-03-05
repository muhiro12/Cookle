import SwiftUI

struct AddMultipleTextsView: View {
    private enum Layout {
        static let placeholderVerticalPadding = CGFloat(Int("8") ?? .zero)
        static let placeholderHorizontalPadding = CGFloat(Int("6") ?? .zero)
        static let textEditorCornerRadius = CGFloat(Int("8") ?? .zero)
    }

    @Environment(\.dismiss)
    private var dismiss

    @Binding private var texts: [String]

    @State private var text: String

    private let title: LocalizedStringKey
    private let placeholder: LocalizedStringKey

    var body: some View {
        TextEditor(text: $text)
            .overlay(alignment: .topLeading) {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(.placeholder)
                    .padding(.vertical, Layout.placeholderVerticalPadding)
                    .padding(.horizontal, Layout.placeholderHorizontalPadding)
                    .allowsHitTesting(false)
                    .hidden(text.isNotEmpty)
            }
            .padding()
            .scrollContentBackground(.hidden)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: Layout.textEditorCornerRadius))
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
                        texts = text.split(separator: "\n", omittingEmptySubsequences: false).map { line in
                            String(line)
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

    init(texts: Binding<[String]>, title: LocalizedStringKey, placeholder: LocalizedStringKey) {
        self._texts = texts
        self.text = texts.wrappedValue.joined(separator: "\n")
        self.title = title
        self.placeholder = placeholder
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
