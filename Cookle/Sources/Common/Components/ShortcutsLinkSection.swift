import AppIntents
import SwiftUI
import TipKit

struct ShortcutsLinkSection: View {
    private let tip: (any Tip)?

    var body: some View {
        Section {
            ShortcutsLink()
                .shortcutsLinkStyle(.automaticOutline)
                .frame(maxWidth: .infinity)
                .popoverTip(
                    tip,
                    arrowEdge: .top
                )
                .listRowBackground(EmptyView())
        }
    }

    init(tip: (any Tip)? = nil) {
        self.tip = tip
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    ShortcutsLinkSection()
}
