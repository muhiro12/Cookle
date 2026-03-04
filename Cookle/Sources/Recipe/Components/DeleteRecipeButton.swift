import SwiftData
import SwiftUI

struct DeleteRecipeButton: View {
    @Environment(Recipe.self)
    private var recipe
    @Environment(\.modelContext)
    private var context
    @Environment(RecipeActionService.self)
    private var recipeActionService

    @State private var isPresented = false

    private let action: (() -> Void)?

    var body: some View {
        Button(role: .destructive) {
            if let action {
                action()
            } else {
                isPresented = true
            }
        } label: {
            Label {
                Text("Delete \(recipe.name)")
            } icon: {
                Image(systemName: "trash")
            }
        }
        .confirmationDialog(
            Text("Delete \(recipe.name)"),
            isPresented: $isPresented
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await recipeActionService.delete(
                            context: context,
                            recipe: recipe
                        )
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }

    init(action: (() -> Void)? = nil) {
        self.action = action
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    DeleteRecipeButton()
        .environment(recipes[0])
}
