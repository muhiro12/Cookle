import MHPlatform
import SwiftData
import SwiftUI

struct SettingsNavigationView: View {
    @Environment(\.modelContext)
    private var context
    @Environment(SettingsActionService.self)
    private var settingsActionService

    @AppStorage(\.isICloudOn)
    private var isICloudOn

    @Binding private var incomingSelection: SettingsContent?

    /// Owned above the split layout so a pending import review survives size-class changes.
    @State private var model = SettingsScreenModel()

    @State private var hasPreparedCaptureImport = false

    @State private var selection: SettingsContent?
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var hasAppliedInitialCompactColumn = false

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn
        ) {
            SettingsSidebarView(
                model: model,
                selection: $selection
            )
        } detail: {
            detailView(for: selection)
        }
        .task {
            applyInitialCompactColumnIfNeeded()
            applyIncomingSelectionIfNeeded()
            #if DEBUG
            if hasPreparedCaptureImport == false {
                hasPreparedCaptureImport = true
                model.prepareCaptureImportIfNeeded(context: context)
            }
            #endif
        }
        .onChange(of: incomingSelection) {
            applyIncomingSelectionIfNeeded()
        }
        .onChange(of: selection) {
            syncPreferredCompactColumn()
        }
        .backupImportReview(
            model: model,
            modelContainer: context.container,
            settingsActionService: settingsActionService,
            isICloudEnabled: isICloudOn
        )
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
            SplitContentPlaceholder("Nothing Selected")
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
