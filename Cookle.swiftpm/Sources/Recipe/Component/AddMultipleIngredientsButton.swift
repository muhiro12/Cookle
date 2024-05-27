import SwiftUI

struct AddMultipleIngredientsButton: View {
    @Binding private var data: [IngredientTuple]
    
    @State private var isPresented = false
    @State private var text = ""
    
    init(ingredients: Binding<[IngredientTuple]>) {
        self._data = ingredients
    }
    
    var body: some View {
        Button("Add Multiple Ingredients at Once") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                TextEditor(text: $text)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                text = ""
                                isPresented = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                let lines = text.split(separator: "\n").map {
                                    String($0)
                                }
                                let contents = stride(from: 0, to: lines.count, by: 2).map {
                                    IngredientTuple(
                                        ingredient: lines[$0],
                                        amount:  lines.endIndex > $0 + 1 ? lines[$0 + 1] : ""
                                    )
                                }
                                data.insert(
                                    contentsOf: contents,
                                    at: data.lastIndex {
                                        $0.ingredient == "" && $0.amount == ""
                                    } ?? .zero
                                )
                                text = ""
                                isPresented = false
                            }
                        }
                    }
                    .padding()
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.separator)
                    }
                    .padding()
            }
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    AddMultipleIngredientsButton(ingredients: .constant([]))
}
