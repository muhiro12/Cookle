import SwiftUI

struct SettingsNavigationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(.isDebugOn) private var isDebugOn

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("License") {
                        LicenseView()
                            .navigationTitle("License")
                    }
                }
                if isDebugOn {
                    Section {
                        NavigationLink("Debug") {
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
    SettingsNavigationView()
        .licenseList {
            Text("LicenseList")
        }
}
