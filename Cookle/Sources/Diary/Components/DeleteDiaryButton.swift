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
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

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
            Text(DiaryDeleteCopy.title(for: diary)),
            isPresented: $isPresented
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await diaryActionService.delete(
                            context: context,
                            diary: diary
                        )
                    } catch {
                        errorMessage = error.localizedDescription
                        isErrorPresented = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text(DiaryDeleteCopy.message(for: diary))
        }
        .alert(
            Text("Cannot Delete Diary"),
            isPresented: $isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                // Dismisses the alert.
            }
        } message: {
            Text(errorMessage)
        }
    }

    init(action: (() -> Void)? = nil) {
        self.action = action
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var diaries: [Diary]
    DeleteDiaryButton()
        .environment(diaries[0])
}
