import MHPlatform
import SwiftUI

struct StoreListView: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime

    var body: some View {
        List {
            appRuntime.subscriptionSectionView()
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
