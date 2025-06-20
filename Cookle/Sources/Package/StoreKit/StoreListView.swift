import StoreKitWrapper
import SwiftUI

struct StoreListView: View {
    @Environment(Store.self) private var store

    var body: some View {
        List {
            store.buildSubscriptionSection()
        }
        .navigationTitle(Text("Subscription"))
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            StoreListView()
        }
    }
}
