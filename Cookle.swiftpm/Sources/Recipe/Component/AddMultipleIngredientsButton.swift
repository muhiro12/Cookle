import SwiftUI

struct AddMultipleIngredientsButton: View {
    @Binding private var data: [IngredientTuple]

    @State private var isPresented = false

    init(ingredients: Binding<[IngredientTuple]>) {
        self._data = ingredients
    }

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
                        return data.flatMap { [$0.ingredient, $0.amount] }
                    },
                    set: { texts in
                        data = stride(from: 0, to: texts.count, by: 2).map {
                            IngredientTuple(
                                ingredient: texts[$0],
                                amount: texts.endIndex > $0 + 1 ? texts[$0 + 1] : ""
                            )
                        }
                    }
                ),
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
}

#Preview {
    AddMultipleIngredientsButton(ingredients: .constant([]))
}
