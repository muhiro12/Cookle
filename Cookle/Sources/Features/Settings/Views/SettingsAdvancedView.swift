import MHUI
import SwiftUI

struct SettingsAdvancedView: View {
    @State private var isDebugPresented = false

    var body: some View {
        List {
            MHContainerContent {
                Section {
                    Button {
                        isDebugPresented = true
                    } label: {
                        Text("Debug")
                            .cookleButtonRowContent()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .mhListChrome(.native)
        .navigationTitle(Text("Advanced"))
        .fullScreenCover(isPresented: $isDebugPresented) {
            DebugNavigationView()
        }
    }
}
