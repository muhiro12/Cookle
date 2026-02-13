import SwiftData
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

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var ingredients: [Ingredient]
    EditTagButton<Ingredient>()
        .environment(ingredients[0])
}
