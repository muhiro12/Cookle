import SwiftData
import SwiftUI

struct TagFormNavigationView<T: Tag>: View {
    @Environment(\.dismiss) private var dismiss

    @Environment(T.self) private var tag: T

    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Value", text: $value)
                } header: {
                    Text("Value")
                }
                Section {
                    ForEach(tag.recipes.orEmpty) {
                        Text($0.name)
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
                        tag.update(value: value)
                        dismiss()
                    } label: {
                        Text("Update")
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
