import SwiftUI

struct DeleteRecipeButton: View {
    @Environment(RecipeEntity.self) private var recipe
    @Environment(\.modelContext) private var context

    @State private var isPresented = false

    private let action: (() -> Void)?

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

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
                if let model = try? recipe.model(context: context) {
                    model.delete()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }
}

#Preview {
    CooklePreview { preview in
        DeleteRecipeButton()
            .environment(preview.recipes[0])
    }
}
