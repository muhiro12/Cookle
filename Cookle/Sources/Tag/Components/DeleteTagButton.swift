import SwiftData
import SwiftUI

struct DeleteTagButton<T: Tag>: View {
    @Environment(T.self) private var tag

    @State private var isConfirmationPresented = false
    @State private var isAlertPresented = false

    private let action: (() -> Void)?

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

    var body: some View {
        Button(role: .destructive) {
            if let action {
                action()
            } else if tag is Ingredient, tag.recipes.orEmpty.isNotEmpty {
                isAlertPresented = true
            } else {
                isConfirmationPresented = true
            }
        } label: {
            Label {
                Text("Delete")
            } icon: {
                Image(systemName: "trash")
            }
        }
        .alert(
            Text("Cannot Delete"),
            isPresented: $isAlertPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This item is used by existing recipes.")
        }
        .confirmationDialog(
            Text("Delete \(tag.value)"),
            isPresented: $isConfirmationPresented
        ) {
            Button("Delete", role: .destructive) {
                tag.delete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var categories: [Category]
    DeleteTagButton<Category>()
        .environment(categories[0])
}
