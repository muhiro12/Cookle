import SwiftUI

struct IngredientObjectView: View {
    @Environment(IngredientObject.self) private var object

    var body: some View {
        List {
            Section {
                Text(object.ingredient?.value ?? "")
            } header: {
                Text("Ingredient")
            }
            Section {
                Text(object.amount)
            } header: {
                Text("Amount")
            }
            Section {
                Text(object.order.description)
            } header: {
                Text("Order")
            }
            Section {
                Text(object.recipe?.name ?? "")
            } header: {
                Text("Recipe")
            }
            Section {
                Text(object.createdTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Created At")
            }
            Section {
                Text(object.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Updated At")
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        IngredientObjectView()
            .environment(preview.ingredientObjects[0])
    }
}
