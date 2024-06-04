import SwiftUI

struct DeleteDiaryButton: View {
    @Environment(Diary.self) private var diary

    @State private var isPresented = false

    var body: some View {
        Button("Delete \(diary.date.formatted(.dateTime.year().month().day()))", systemImage: "trash") {
            isPresented = true
        }
        .alert("Delete \(diary.date.formatted(.dateTime.year().month().day()))", isPresented: $isPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                diary.delete()
            }
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
