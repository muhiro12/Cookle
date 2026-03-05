import SwiftUI

struct AddMultipleIngredientsButton: View {
    private enum Constants {
        static let pairStride = Int("2") ?? .zero
        static let valueOffset = Int("1") ?? .zero
    }

    @Binding private var data: [RecipeFormIngredient]

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Text("Add Multiple Ingredients at Once")
        }
        .sheet(isPresented: $isPresented) {
            AddMultipleTextsNavigationView(
                texts: ingredientTexts,
                title: "Ingredients",
                placeholder: ingredientPlaceholder
            )
            .interactiveDismissDisabled()
        }
    }

    var ingredientTexts: Binding<[String]> {
        .init(
            get: {
                currentTexts()
            },
            set: { texts in
                updateIngredients(from: texts)
            }
        )
    }

    var ingredientPlaceholder: LocalizedStringKey {
        """
        Spaghetti
        200g
        Eggs
        2
        Parmesan cheese
        50g
        Pancetta
        100g
        Black pepper
        to taste
        Salt
        to taste
        """
    }

    init(ingredients: Binding<[RecipeFormIngredient]>) {
        self._data = ingredients
    }

    func currentTexts() -> [String] {
        if data.count == 1,
           data[0].ingredient.isEmpty,
           data[0].amount.isEmpty {
            return []
        }
        return data.flatMap { ingredient in
            [ingredient.ingredient, ingredient.amount]
        }
    }

    func updateIngredients(from texts: [String]) {
        data = stride(
            from: .zero,
            to: texts.count,
            by: Constants.pairStride
        ).map { index in
            .init(
                ingredient: texts[index],
                amount: texts.endIndex > index + Constants.valueOffset
                    ? texts[index + Constants.valueOffset]
                    : .empty
            )
        }
    }
}

#Preview {
    AddMultipleIngredientsButton(ingredients: .constant([]))
}
