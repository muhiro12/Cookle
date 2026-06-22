import SwiftData
import SwiftUI

struct TagFormNavigationView<T: Tag>: View {
    var body: some View {
        NavigationStack {
            TagFormView<T>()
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var categories: [Category]
    TagFormNavigationView<Category>()
        .environment(categories[0])
}
