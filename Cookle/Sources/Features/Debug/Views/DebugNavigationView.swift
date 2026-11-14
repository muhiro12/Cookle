import SwiftUI

struct DebugNavigationView: View {
    var body: some View {
        #if DEBUG
        DevelopmentDebugNavigationView()
        #else
        NavigationStack {
            DebugStatusView(title: "Debug")
                .toolbar {
                    ToolbarItem {
                        CloseButton()
                    }
                }
        }
        #endif
    }
}
