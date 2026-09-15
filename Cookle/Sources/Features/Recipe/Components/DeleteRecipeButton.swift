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
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    private let action: (() -> Void)?
    private let showsRecipeName: Bool

    var body: some View {
        Button(role: .destructive) {
            if let action {
                action()
            } else {
                isPresented = true
            }
        } label: {
            Label {
                if showsRecipeName {
                    Text("Delete \(recipe.name)")
                } else {
                    Text("Delete")
                }
            } icon: {
                Image(systemName: "trash")
                    .accessibilityHidden(true)
            }
        }
        .confirmationDialog(
            Text(RecipeDeleteCopy.title(for: recipe)),
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
                        errorMessage = error.localizedDescription
                        isErrorPresented = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text(RecipeDeleteCopy.message(for: recipe))
        }
        .alert(
            Text("Cannot Delete Recipe"),
            isPresented: $isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                // Dismisses the alert.
            }
        } message: {
            Text(errorMessage)
        }
    }

    init(showsRecipeName: Bool = true, action: (() -> Void)? = nil) {
        self.showsRecipeName = showsRecipeName
        self.action = action
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    DeleteRecipeButton()
        .environment(recipes[0])
}
