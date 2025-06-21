import SwiftUI

struct TagFormNavigationView<T: Tag>: View {
    var body: some View {
        NavigationStack {
            TagFormView<T>()
        }
    }
}

#Preview {
    TagFormNavigationView<Category>()
}
