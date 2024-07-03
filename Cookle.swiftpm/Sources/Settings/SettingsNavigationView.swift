import SwiftUI
import SwiftUtilities

struct SettingsNavigationView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(.isSubscribeOn) private var isSubscribeOn
    @AppStorage(.isICloudOn) private var isICloudOn
    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var isDebugPresented = false

    var body: some View {
        NavigationStack {
            List {
                if isSubscribeOn {
                    Section {
                        Toggle("iCloud On", isOn: $isICloudOn)
                    } header: {
                        Text("Settings")
                    }
                } else {
                    StoreSection()
                }
                Section {
                    NavigationLink("Licenses") {
                        LicenseView()
                    }
                }
                if isDebugOn {
                    Section {
                        Toggle("Debug On", isOn: $isDebugOn)
                        Button {
                            isDebugPresented = true
                        } label: {
                            Text("DebugNavigationView")
                        }
                    } header: {
                        Text("Debug")
                    }
                }
            }
            .navigationTitle(Text("Settings"))
            .toolbar {
                ToolbarItem {
                    CloseButton()
                }
            }
            .fullScreenCover(isPresented: $isDebugPresented) {
                DebugNavigationView()
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        SettingsNavigationView()
    }
}
