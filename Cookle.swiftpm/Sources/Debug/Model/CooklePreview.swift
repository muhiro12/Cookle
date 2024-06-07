import SwiftUI

struct CooklePreview<Content: View>: View {
    private let content: (CooklePreviewStore) -> Content

    private let preview = CooklePreviewStore()
    private let store = Store()

    init(_ content: @escaping (CooklePreviewStore) -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            Group {
                ModelContainerPreview {
                    content($0)
                }
                .environment(preview)
            }
            .environment(store)
        }
        .cooklePlaygroundsEnvironment()
    }
}

#Preview {
    CooklePreview { preview in
        List(preview.ingredients) { ingredient in
            Text(ingredient.value)
        }
    }
}
