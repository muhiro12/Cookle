import SwiftUI

struct LicenseView: View {
    @Environment(LicenseListPackage.self) private var licenseList

    var body: some View {
        licenseList()
    }
}

#Preview {
    CooklePreview { _ in
        LicenseView()
    }
}
