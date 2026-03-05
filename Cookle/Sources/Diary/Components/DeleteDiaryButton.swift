import SwiftData
import SwiftUI

struct DeleteDiaryButton: View {
    @Environment(Diary.self)
    private var diary
    @Environment(\.modelContext)
    private var context
    @Environment(DiaryActionService.self)
    private var diaryActionService

    @State private var isPresented = false

    private let action: (() -> Void)?

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
                    .accessibilityHidden(true)
            }
        }
        .confirmationDialog(
            Text("Delete \(diary.date.formatted(.dateTime.year().month().day()))"),
            isPresented: $isPresented
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    _ = await diaryActionService.delete(
                        context: context,
                        diary: diary
                    )
                }
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }

    init(action: (() -> Void)? = nil) {
        self.action = action
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var diaries: [Diary]
    DeleteDiaryButton()
        .environment(diaries[0])
}
