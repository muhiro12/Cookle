import MHPlatform
import SwiftUI

struct LicenseView: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime

    var body: some View {
        appRuntime.licensesView()
            .navigationTitle(Text("Licenses"))
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    LicenseView()
}
