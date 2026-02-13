import LicenseListWrapper
import SwiftUI

struct LicenseView: View {
    var body: some View {
        LicenseListView()
            .navigationTitle(Text("Licenses"))
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    LicenseView()
}
