import SwiftUI

struct ImportDataButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Import", systemImage: "square.and.arrow.down")
        }
    }
}
