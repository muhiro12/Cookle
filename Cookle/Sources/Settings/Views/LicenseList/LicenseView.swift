import MHAppRuntimeCore
import SwiftUI

struct LicenseView: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime

    var body: some View {
        appRuntime.licensesView()
            .navigationTitle(Text("Licenses"))
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        LicenseView()
    }
}
