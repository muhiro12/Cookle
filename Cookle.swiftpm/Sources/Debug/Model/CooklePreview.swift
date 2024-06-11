import SwiftUI

struct CooklePreview<Content: View>: View {
    private let content: (CooklePreviewStore) -> Content

    private let preview = CooklePreviewStore()

    init(_ content: @escaping (CooklePreviewStore) -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            ModelContainerPreview {
                content($0)
            }
            .environment(preview)
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
