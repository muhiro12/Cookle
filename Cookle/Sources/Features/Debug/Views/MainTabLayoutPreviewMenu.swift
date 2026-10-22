#if DEBUG
import SwiftUI

/// Temporary, scene-local comparison controls. Selecting AI never enables a model.
struct MainTabLayoutPreviewMenu: View {
    @Environment(MainNavigationModel.self)
    private var navigationModel

    var body: some View {
        Menu {
            Section("Tab Layout Preview") {
                ForEach(MainTabLayout.allCases, id: \.self) { layout in
                    Button {
                        // Move first so iOS never receives a hidden selected tab.
                        if !layout.tabs.contains(navigationModel.selectedTab) {
                            navigationModel.selectedTab = .diary
                        }
                        navigationModel.tabLayoutPreview = layout
                    } label: {
                        if navigationModel.tabLayoutPreview == layout {
                            Label(layout.previewTitle, systemImage: "checkmark")
                        } else {
                            Text(layout.previewTitle)
                        }
                    }
                }
            }
            Button("Use Device Availability") {
                navigationModel.selectedTab = .diary
                navigationModel.tabLayoutPreview = nil
            }
        } label: {
            Label("Tab Layout Preview", systemImage: "rectangle.3.group")
        }
        .accessibilityIdentifier("tabLayoutPreview")
    }
}

private extension MainTabLayout {
    var previewTitle: LocalizedStringKey {
        switch self {
        case .aiProminent:
            "A: AI Available, Separate AI"
        case .aiIntegrated:
            "B: AI Available, Integrated AI"
        case .searchProminent:
            "C: No AI, Separate Search"
        case .searchIntegrated:
            "D: No AI, Integrated Search"
        case .aiSearchTab:
            "E: AI with Native Search Transition"
        case .aiRequestForm:
            "F: Separate AI, Request Form"
        case .recipeModal:
            "G: Recipe Modal, Separate Search"
        case .aiSearchToolbar:
            "H: Separate AI, Native Toolbar Input"
        }
    }
}
#endif
