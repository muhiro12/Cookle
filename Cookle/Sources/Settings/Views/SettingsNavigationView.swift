import SwiftUI

struct SettingsNavigationView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Binding private var incomingSelection: SettingsContent?

    @State private var selection: SettingsContent?

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView(columnVisibility: .constant(.all)) {
                    SettingsSidebarView(selection: $selection)
                } detail: {
                    detailView(for: selection)
                }
            } else {
                NavigationStack {
                    SettingsSidebarView(selection: $selection)
                        .listStyle(.insetGrouped)
                        .navigationDestination(isPresented: $selection.isPresent()) {
                            detailView(for: selection)
                        }
                }
            }
        }
        .task {
            applyIncomingSelectionIfNeeded()
        }
        .onChange(of: incomingSelection) {
            applyIncomingSelectionIfNeeded()
        }
    }

    init(
        incomingSelection: Binding<SettingsContent?> = .constant(nil)
    ) {
        _incomingSelection = incomingSelection
    }
}

private extension SettingsNavigationView {
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
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    SettingsNavigationView()
}
