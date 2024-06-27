import SwiftUI

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
                        Button {
                            isDebugPresented = true
                        } label: {
                            Text("DebugNavigationView")
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
