import GoogleMobileAdsWrapper
import StoreKitWrapper
import SwiftUI

struct CooklePreview<Content: View>: View {
    @AppStorage(.isDebugOn) private var isDebugOn

    private let content: (CooklePreviewStore) -> Content
    private let preview: CooklePreviewStore

    private var previewStore: Store
    private var previewGoogleMobileAdsController: GoogleMobileAdsController

    @MainActor
    init(_ content: @escaping (CooklePreviewStore) -> Content) {
        self.content = content
        self.preview = .init()

        self.previewStore = .init()
        self.previewGoogleMobileAdsController = .init(adUnitID: Secret.adUnitIDDev)
    }

    var body: some View {
        ModelContainerPreview {
            content($0)
        }
        .task {
            isDebugOn = true
        }
        .environment(preview)
        .environment(previewStore)
        .environment(previewGoogleMobileAdsController)
    }
}

#Preview {
    CooklePreview { preview in
        List(preview.ingredients) { ingredient in
            Text(ingredient.value)
        }
    }
}
