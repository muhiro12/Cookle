import SwiftUI

struct AddMultipleIngredientsButton: View {
    @Binding private var data: [IngredientTuple]

    @State private var isPresented = false

    init(ingredients: Binding<[IngredientTuple]>) {
        self._data = ingredients
    }

    var body: some View {
        Button("Add Multiple Ingredients at Once") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            AddMultipleTextsView(
                texts: .init(
                    get: {
                        data.flatMap { [$0.ingredient, $0.amount] }
                    },
                    set: { texts in
                        let contents = stride(from: 0, to: texts.count, by: 2).map {
                            IngredientTuple(
                                ingredient: texts[$0],
                                amount: texts.endIndex > $0 + 1 ? texts[$0 + 1] : ""
                            )
                        }
                        data.insert(
                            contentsOf: contents,
                            at: data.lastIndex {
                                $0.ingredient == "" && $0.amount == ""
                            } ?? .zero
                        )
                    }
                )
            )
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    AddMultipleIngredientsButton(ingredients: .constant([]))
}
