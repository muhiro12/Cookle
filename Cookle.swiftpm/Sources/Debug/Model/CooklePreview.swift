import SwiftUI

struct CooklePreview<Content: View>: View {
    private let content: (CooklePreviewStore) -> Content

    private let store = CooklePreviewStore()

    init(_ content: @escaping (CooklePreviewStore) -> Content) {
        self.content = content
    }

    var body: some View {
        ModelContainerPreview {
            content($0)
        }
        .environment(store)
        .googleMobileAds {
            Text("GoogleMobileAds \($0)")
        }
        .licenseList {
            Text("LicenseList")
        }
    }
}

#Preview {
    CooklePreview { preview in
        List(preview.ingredients) { ingredient in
            Text(ingredient.value)
        }
    }
}
