import SwiftUI

struct SettingsNavigationView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(.isSubscribeOn) private var isSubscribeOn
    @AppStorage(.isICloudOn) private var isICloudOn
    @AppStorage(.isDebugOn) private var isDebugOn

    var body: some View {
        NavigationStack {
            List {
                if isSubscribeOn {
                    Section("Settings") {
                        Toggle("iCloud On", isOn: $isICloudOn)
                    }
                } else {
                    StoreSection()
                }
                Section {
                    NavigationLink("License") {
                        LicenseView()
                            .navigationTitle("License")
                    }
                }
                if isDebugOn {
                    Section("Debug") {
                        Toggle("Debug On", isOn: $isDebugOn)
                        NavigationLink("DebugNavigationView") {
                            DebugNavigationView()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        SettingsNavigationView()
    }
}
