import MHUI
import SwiftData
import SwiftUI

struct IngredientObjectView: View {
    @Environment(IngredientObject.self)
    private var object

    var body: some View {
        List {
            MHContainerContent {
                ingredientSection
                amountSection
                orderSection
                recipeSection
                createdAtSection
                updatedAtSection
            }
        }
        .mhListChrome(.native)
    }

    var ingredientSection: some View {
        Section {
            Text(object.ingredient?.value ?? "")
        } header: {
            Text("Ingredient")
        }
    }

    var amountSection: some View {
        Section {
            Text(object.amount)
        } header: {
            Text("Amount")
        }
    }

    var orderSection: some View {
        Section {
            Text(object.order.description)
        } header: {
            Text("Order")
        }
    }

    var recipeSection: some View {
        Section {
            Text(object.recipe?.name ?? "")
        } header: {
            Text("Recipe")
        }
    }

    var createdAtSection: some View {
        Section {
            Text(object.createdTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Created At")
        }
    }

    var updatedAtSection: some View {
        Section {
            Text(object.modifiedTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Updated At")
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var ingredientObjects: [IngredientObject]
    IngredientObjectView()
        .environment(ingredientObjects[0])
}
