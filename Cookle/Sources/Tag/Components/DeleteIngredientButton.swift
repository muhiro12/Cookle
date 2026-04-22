import SwiftData
import SwiftUI

struct DeleteIngredientButton: View {
    @Environment(Ingredient.self)
    private var ingredient
    @Environment(\.modelContext)
    private var context
    @Environment(TagActionService.self)
    private var tagActionService

    @State private var isPresented = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    private let afterDelete: (() -> Void)?

    private var isDeletionAvailable: Bool {
        ingredient.recipes.orEmpty.isEmpty
    }

    var body: some View {
        Button(role: .destructive) {
            isPresented = true
        } label: {
            Label {
                Text("Delete")
            } icon: {
                Image(systemName: "trash")
                    .accessibilityHidden(true)
            }
        }
        .disabled(!isDeletionAvailable)
        .confirmationDialog(
            Text(IngredientDeleteCopy.title(for: ingredient)),
            isPresented: $isPresented
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await tagActionService.delete(
                            context: context,
                            ingredient: ingredient
                        )
                        afterDelete?()
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
            Text(IngredientDeleteCopy.message(for: ingredient))
        }
        .alert(
            Text("Cannot Delete Ingredient"),
            isPresented: $isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                // Dismisses the alert.
            }
        } message: {
            Text(errorMessage)
        }
    }

    init(afterDelete: (() -> Void)? = nil) {
        self.afterDelete = afterDelete
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var ingredients: [Ingredient]
    DeleteIngredientButton()
        .environment(ingredients[0])
}
