import SwiftUI

struct SettingsNavigationView: View {
    @State private var selection: SettingsContent?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SettingsSidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .subscription:
                StoreListView()
            case .migrationLogs:
                MigrationTraceLogView()
            case .license:
                LicenseView()
            case .none:
                EmptyView()
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    SettingsNavigationView()
}
