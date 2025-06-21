import SwiftUI

struct AddMultipleTextsNavigationView: View {
    @Binding var texts: [String]
    private let title: LocalizedStringKey
    private let placeholder: LocalizedStringKey

    init(texts: Binding<[String]>, title: LocalizedStringKey, placeholder: LocalizedStringKey) {
        self._texts = texts
        self.title = title
        self.placeholder = placeholder
    }

    var body: some View {
        NavigationStack {
            AddMultipleTextsView(texts: $texts, title: title, placeholder: placeholder)
        }
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
