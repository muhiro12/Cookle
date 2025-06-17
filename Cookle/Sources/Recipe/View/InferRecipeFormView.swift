import AppIntents
import SwiftUI

@available(iOS 26.0, *)
struct InferRecipeFormView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var name: String
    @Binding private var servingSize: String
    @Binding private var cookingTime: String
    @Binding private var ingredients: [RecipeFormIngredient]
    @Binding private var steps: [String]
    @Binding private var categories: [String]
    @Binding private var note: String

    @State private var text = ""

    private let placeholder: LocalizedStringKey = """
        Spaghetti Carbonara for 2 people.
        Ingredients: Spaghetti 200g, Eggs 2, Pancetta 100g.
        Cook spaghetti. Fry pancetta. Mix eggs and cheese. Combine all.
        """

    init(
        name: Binding<String>,
        servingSize: Binding<String>,
        cookingTime: Binding<String>,
        ingredients: Binding<[RecipeFormIngredient]>,
        steps: Binding<[String]>,
        categories: Binding<[String]>,
        note: Binding<String>
    ) {
        self._name = name
        self._servingSize = servingSize
        self._cookingTime = cookingTime
        self._ingredients = ingredients
        self._steps = steps
        self._categories = categories
        self._note = note
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
                            if let inference = try? await InferRecipeIntent.perform(text) {
                                name = inference.name
                                servingSize = inference.servingSize == 0 ? "" : inference.servingSize.description
                                cookingTime = inference.cookingTime == 0 ? "" : inference.cookingTime.description
                                ingredients = inference.ingredients.map { ($0.ingredient, $0.amount) } + [("", "")]
                                steps = inference.steps + [""]
                                categories = inference.categories + [""]
                                note = inference.note
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
