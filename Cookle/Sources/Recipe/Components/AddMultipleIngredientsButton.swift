import SwiftUI

struct AddMultipleIngredientsButton: View {
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
                texts: .init(
                    get: {
                        if data.count == 1,
                           data[0].ingredient == "",
                           data[0].amount == "" {
                            return []
                        }
                        return data.flatMap { ingredient in
                            [ingredient.ingredient, ingredient.amount]
                        }
                    },
                    set: { texts in
                        data = stride(from: 0, to: texts.count, by: 2).map { index in
                            RecipeFormIngredient(
                                ingredient: texts[index],
                                amount: texts.endIndex > index + 1 ? texts[index + 1] : .empty
                            )
                        }
                    }
                ),
                title: "Ingredients",
                placeholder: """
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
            )
            .interactiveDismissDisabled()
        }
    }

    init(ingredients: Binding<[RecipeFormIngredient]>) {
        self._data = ingredients
    }
}

#Preview {
    AddMultipleIngredientsButton(ingredients: .constant([]))
}
