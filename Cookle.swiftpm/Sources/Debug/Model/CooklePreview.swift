import SwiftUI

struct CooklePreview<Content: View>: View {
    private let content: (CooklePreviewStore) -> Content

    private let preview = CooklePreviewStore()
    private let store = Store()

    init(_ content: @escaping (CooklePreviewStore) -> Content) {
        self.content = content
    }

    var body: some View {
        ModelContainerPreview {
            content($0)
        }
        .environment(preview)
        .environment(store)
        .secret(["groupID": "", "productID": ""])
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
