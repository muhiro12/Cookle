import SwiftUI

struct CancelButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .cancel, action: action) {
            Label("Cancel", systemImage: "xmark")
        }
    }
}

#Preview {
    CancelButton {
        // Preview only.
    }
}
