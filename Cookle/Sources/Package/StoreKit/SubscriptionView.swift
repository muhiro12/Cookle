import SwiftUI

struct SubscriptionView: View {
    @Environment(StoreKitPackage.self) private var storeKit

    var body: some View {
        List {
            storeKit()
        }
        .navigationTitle(Text("Subscription"))
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            SubscriptionView()
        }
    }
}
