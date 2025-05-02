import SwiftUI

struct SettingsNavigationView: View {
    @State private var selection: SettingsContent?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SettingsSidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .license:
                LicenseView()
            case .none:
                EmptyView()
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        SettingsNavigationView()
    }
}
