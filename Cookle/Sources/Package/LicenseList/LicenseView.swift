import SwiftUI
import LicenseListWrapper

struct LicenseView: View {
    var body: some View {
        LicenseListView()
            .navigationTitle(Text("Licenses"))
    }
}

#Preview {
    CooklePreview { _ in
        LicenseView()
    }
}
