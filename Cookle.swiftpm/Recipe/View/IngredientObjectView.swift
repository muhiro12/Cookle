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
            Section("Recipe") {
                Text(object.recipe?.name ?? "")
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
