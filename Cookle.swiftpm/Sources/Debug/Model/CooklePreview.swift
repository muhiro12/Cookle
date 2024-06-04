import SwiftUI

struct CooklePreview<Content: View>: View {
    private let content: (ModelContainerPreview<Content>) -> Content
    
    init(_ content: @escaping (ModelContainerPreview<Content>) -> Content) {
        self.content = content
    }
    
    var body: some View {
        ModelContainerPreview {
            content($0)
        }
        .googleMobileAds {
            Text("GoogleMobileAds \($0)")
        }
        .licenseList {
            Text("LicenseList")
        }
    }
}

#Preview {
    CooklePreview { _ in
        Text("Cookle")
    }
}
