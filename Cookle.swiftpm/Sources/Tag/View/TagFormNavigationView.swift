import SwiftData
import SwiftUI

struct TagFormNavigationView<T: Tag>: View {
    @Environment(\.dismiss) private var dismiss

    @Environment(T.self) private var tag: T

    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Value") {
                    TextField("Value", text: $value)
                }
                Section("Recipes") {
                    ForEach(tag.recipes.orEmpty) {
                        Text($0.name)
                    }
                }
            }
            .navigationTitle("Edit " + tag.value)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        tag.update(value: value)
                        dismiss()
                    }
                    .disabled(value.isEmpty)
                }
            }
        }
        .interactiveDismissDisabled()
        .task {
            value = tag.value
        }
    }
}

#Preview {
    CooklePreview { preview in
        TagFormNavigationView<Category>()
            .environment(preview.categories[0])
    }
}
