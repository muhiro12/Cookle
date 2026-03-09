import MHAppRuntimeCore
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

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        StoreListView()
    }
}
