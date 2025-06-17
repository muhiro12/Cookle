import SwiftUI

struct StoreListView: View {
    var body: some View {
        List {
            StoreSection()
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
