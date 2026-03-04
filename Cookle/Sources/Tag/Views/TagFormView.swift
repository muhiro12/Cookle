import SwiftData
import SwiftUI

struct TagFormView<T: Tag>: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.modelContext)
    private var context

    @Environment(T.self)
    private var tag: T
    @Environment(TagActionService.self)
    private var tagActionService

    @State private var value = ""
    @State private var errorMessage = ""
    @State private var isErrorPresented = false

    var body: some View {
        Form {
            Section {
                TextField(text: $value) {
                    Text("Spaghetti")
                }
            } header: {
                Text("Value")
            }
            Section {
                ForEach(tag.recipes.orEmpty) { recipe in
                    Text(recipe.name)
                }
            } header: {
                Text("Recipes")
            }
        }
        .navigationTitle("Edit " + tag.value)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        do {
                            try await tagActionService.rename(
                                context: context,
                                tag: tag,
                                value: value
                            )
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            isErrorPresented = true
                        }
                    }
                } label: {
                    Text("Update")
                }
                .disabled(value.isEmpty)
            }
        }
        .interactiveDismissDisabled()
        .alert(
            Text("Cannot Update"),
            isPresented: $isErrorPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            value = tag.value
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var categories: [Category]
    TagFormNavigationView<Category>()
        .environment(categories[0])
}
