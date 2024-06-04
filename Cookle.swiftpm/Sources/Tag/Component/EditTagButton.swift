import SwiftUI

struct EditTagButton<T: Tag>: View {
    @Environment(T.self) private var tag

    @State private var isPresented = false

    var body: some View {
        Button("Edit \(tag.value)", systemImage: "pencil") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            TagFormNavigationView<T>()
        }
    }
}

#Preview {
    CooklePreview { preview in
        EditTagButton<Ingredient>()
            .environment(preview.ingredients[0])
    }
}
