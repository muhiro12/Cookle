import SwiftUI

struct DeleteRecipeButton: View {
    @Environment(Recipe.self) private var recipe

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
        .alert("Delete \(recipe.name)", isPresented: $isPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                recipe.delete()
            }
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
