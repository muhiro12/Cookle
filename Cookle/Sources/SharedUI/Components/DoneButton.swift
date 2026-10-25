import SwiftUI

struct DoneButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Done", systemImage: "checkmark")
        }
    }
}

#Preview {
    DoneButton {
        // Preview only.
    }
}
