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

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        StoreListView()
    }
}
