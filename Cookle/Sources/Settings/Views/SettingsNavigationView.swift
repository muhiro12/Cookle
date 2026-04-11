import SwiftUI

struct SettingsNavigationView: View {
    @Binding private var incomingSelection: SettingsContent?

    @State private var selection: SettingsContent?
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var hasAppliedInitialCompactColumn = false

    var body: some View {
        NavigationSplitView(
            columnVisibility: .constant(.all),
            preferredCompactColumn: $preferredCompactColumn
        ) {
            SettingsSidebarView(selection: $selection)
        } detail: {
            detailView(for: selection)
        }
        .task {
            applyInitialCompactColumnIfNeeded()
            applyIncomingSelectionIfNeeded()
        }
        .onChange(of: incomingSelection) {
            applyIncomingSelectionIfNeeded()
        }
        .onChange(of: selection) {
            syncPreferredCompactColumn()
        }
    }

    init(
        incomingSelection: Binding<SettingsContent?> = .constant(nil)
    ) {
        _incomingSelection = incomingSelection
    }
}

private extension SettingsNavigationView {
    func applyInitialCompactColumnIfNeeded() {
        guard !hasAppliedInitialCompactColumn else {
            return
        }

        hasAppliedInitialCompactColumn = true
        syncPreferredCompactColumn()
    }

    @ViewBuilder
    func detailView(for selection: SettingsContent?) -> some View {
        switch selection {
        case .subscription:
            StoreListView()
        case .license:
            LicenseView()
        case .none:
            EmptyView()
        }
    }

    func applyIncomingSelectionIfNeeded() {
        guard let incomingSelection else {
            return
        }

        selection = incomingSelection
        self.incomingSelection = nil
        syncPreferredCompactColumn()
    }

    func syncPreferredCompactColumn() {
        preferredCompactColumn = CompactSplitColumnPolicy.twoColumn(
            hasDetailSelection: selection != nil
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    SettingsNavigationView()
}
