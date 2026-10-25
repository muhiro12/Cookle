import SwiftUI

struct ImportDataButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Import", systemImage: "tray.and.arrow.down")
        }
    }
}
