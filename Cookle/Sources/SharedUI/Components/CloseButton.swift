import SwiftUI

struct CloseButton: View {
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Label("Close", systemImage: "xmark")
        }
    }
}

#Preview {
    NavigationStack {
        List {
            CloseButton()
        }
        .toolbar {
            ToolbarItem {
                CloseButton()
            }
        }
    }
}
