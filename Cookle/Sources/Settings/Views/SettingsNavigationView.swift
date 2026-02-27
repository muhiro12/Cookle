import SwiftUI

struct SettingsNavigationView: View {
    @Binding private var incomingSelection: SettingsContent?

    @State private var selection: SettingsContent?

    init(
        incomingSelection: Binding<SettingsContent?> = .constant(nil)
    ) {
        _incomingSelection = incomingSelection
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SettingsSidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .subscription:
                StoreListView()
            case .license:
                LicenseView()
            case .none:
                EmptyView()
            }
        }
        .task {
            applyIncomingSelectionIfNeeded()
        }
        .onChange(of: incomingSelection) {
            applyIncomingSelectionIfNeeded()
        }
    }
}

private extension SettingsNavigationView {
    func applyIncomingSelectionIfNeeded() {
        guard let incomingSelection else {
            return
        }
        selection = incomingSelection
        self.incomingSelection = nil
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    SettingsNavigationView()
}
