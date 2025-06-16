import SwiftUI

struct ShortcutsLinkSection: View {
    @Environment(AppIntentsPackage.self) private var appIntents

    var body: some View {
        Section {
            appIntents()
                .frame(maxWidth: .infinity)
                .listRowBackground(EmptyView())
            NavigationLink {
                AppIntentsNavigationView()
            } label: {
                Text("Run Shortcuts")
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        ShortcutsLinkSection()
    }
}
