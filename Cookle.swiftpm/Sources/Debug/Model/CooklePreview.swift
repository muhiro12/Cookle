import SwiftUI

struct CooklePreview<Content: View>: View {
    @AppStorage(.isDebugOn) private var isDebugOn

    private let content: (CooklePreviewStore) -> Content

    private let preview = CooklePreviewStore()

    init(_ content: @escaping (CooklePreviewStore) -> Content) {
        self.content = content
    }

    var body: some View {
        ModelContainerPreview {
            content($0)
        }
        .task {
            isDebugOn = true
        }
        .environment(preview)
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
