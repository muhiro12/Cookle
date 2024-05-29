import SwiftUI

struct IngredientObjectView: View {
    @Environment(IngredientObject.self) private var object

    var body: some View {
        List {
            Section("Ingredient") {
                Text(object.ingredient.value)
            }
            Section("Amount") {
                Text(object.amount)
            }
            Section("Order") {
                Text(object.order.description)
            }
            Section("Recipe") {
                Text(object.recipe?.name ?? "")
            }
            Section("Created At") {
                Text(object.createdTimestamp.formatted(.dateTime.year().month().day()))
            }
            Section("Updated At") {
                Text(object.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            }
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        IngredientObjectView()
            .environment(preview.ingredientObjects[0])
    }
}
