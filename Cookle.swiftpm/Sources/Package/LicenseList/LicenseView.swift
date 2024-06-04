import SwiftUI

struct LicenseView: View {
    @Environment(CookleLicenseList.self) private var licenseList

    var body: some View {
        licenseList()
    }
}

#Preview {
    LicenseView()
}
