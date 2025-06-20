import AppIntents
import SwiftUI

struct ShortcutsLinkSection: View {
    var body: some View {
        Section {
            ShortcutsLink()
                .shortcutsLinkStyle(.automaticOutline)
                .frame(maxWidth: .infinity)
                .listRowBackground(EmptyView())
        }
    }
}

#Preview {
    CooklePreview { _ in
        ShortcutsLinkSection()
    }
}
