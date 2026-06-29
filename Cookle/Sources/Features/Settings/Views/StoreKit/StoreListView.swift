import MHPlatform
import SwiftUI

struct StoreListView: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime

    var body: some View {
        List {
            appRuntime.subscriptionSectionView()
        }
        .cookleListChrome()
        .navigationTitle(Text("Subscription"))
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        StoreListView()
    }
}
