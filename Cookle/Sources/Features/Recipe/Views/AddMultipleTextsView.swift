import MHUI
import SwiftUI

struct AddMultipleTextsView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.mhDesignMetrics)
    private var designMetrics

    @Binding private var texts: [String]

    @State private var text: String

    private let title: LocalizedStringKey
    private let placeholder: LocalizedStringKey

    var body: some View {
        TextEditor(text: $text)
            .accessibilityLabel(Text(title))
            .accessibilityValue(Text(verbatim: text))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(.placeholder)
                        .padding(
                            .vertical,
                            RecipeTextEditorLayout.placeholderVerticalPadding(
                                metrics: designMetrics
                            )
                        )
                        .padding(
                            .horizontal,
                            RecipeTextEditorLayout.placeholderHorizontalPadding
                        )
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .padding()
            .scrollContentBackground(.hidden)
            .mhInputChrome()
            .padding()
            .cookleScreenChrome()
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
