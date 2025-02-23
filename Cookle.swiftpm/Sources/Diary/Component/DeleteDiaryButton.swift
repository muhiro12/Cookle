import SwiftUI

struct DeleteDiaryButton: View {
    @Environment(Diary.self) private var diary

    @State private var isPresented = false

    private let action: (() -> Void)?

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

    var body: some View {
        Button(role: .destructive) {
            if let action {
                action()
            } else {
                isPresented = true
            }
        } label: {
            Label {
                Text("Delete")
            } icon: {
                Image(systemName: "trash")
            }
        }
        .confirmationDialog(
            Text("Delete \(diary.date.formatted(.dateTime.year().month().day()))"),
            isPresented: $isPresented
        ) {
            Button("Delete", role: .destructive) {
                diary.delete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }
}

#Preview {
    CooklePreview { preview in
        DeleteDiaryButton()
            .environment(preview.diaries[0])
    }
}
