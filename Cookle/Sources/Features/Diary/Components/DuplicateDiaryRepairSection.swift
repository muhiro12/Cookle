import MHUI
import SwiftData
import SwiftUI

struct DuplicateDiaryRepairSection: View {
    private enum Layout {
        static let contentSpacing: CGFloat = 6
        static let verticalPadding: CGFloat = 4
    }

    @Environment(\.modelContext)
    private var context
    @Environment(DiaryActionService.self)
    private var diaryActionService

    @AppStorage(\.isICloudOn)
    private var isICloudOn

    @Query(.diaries(.all))
    private var diaries: [Diary]

    @State private var isConfirmationPresented = false
    @State private var isRepairInProgress = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    var body: some View {
        Group {
            if hasDuplicateDays {
                repairSection
            }
        }
        .confirmationDialog(
            Text("Merge Duplicate Diaries?"),
            isPresented: $isConfirmationPresented
        ) {
            Button("Merge", role: .destructive) {
                repairDuplicateDays()
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text(confirmationMessage)
        }
        .alert(
            Text("Cannot Merge Diaries"),
            isPresented: $isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                // Dismisses the alert.
            }
        } message: {
            Text(errorMessage)
        }
    }
}

private extension DuplicateDiaryRepairSection {
    var repairSection: some View {
        MHGroupedRows {
            VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                Label {
                    Text("Duplicate Diaries Found")
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .accessibilityHidden(true)
                }
                .font(.headline)
                Text(
                    """
                    Cookle found multiple diary entries for the same day. \
                    Merge them before exporting a backup.
                    """
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, Layout.verticalPadding)
            .accessibilityElement(children: .combine)

            Button(
                "Merge Duplicate Diaries",
                systemImage: "arrow.triangle.merge",
                role: .destructive
            ) {
                isConfirmationPresented = true
            }
            .disabled(isRepairInProgress)
        }
        .mhSection("Data Repair")
    }

    var hasDuplicateDays: Bool {
        Dictionary(grouping: diaries) { diary in
            Calendar.current.startOfDay(for: diary.date)
        }
        .values
        .contains { diaries in
            diaries.count > 1
        }
    }

    var confirmationMessage: String {
        if isICloudOn {
            return String(
                localized: """
                Cookle will keep the newest entry for each day, combine its meals and different notes, \
                and remove only the extra entries. Recipes stay saved. The changes sync to other devices \
                using the same iCloud account. This cannot be undone.
                """
            )
        }
        return String(
            localized: """
            Cookle will keep the newest entry for each day, combine its meals and different notes, \
            and remove only the extra entries. Recipes stay saved. This cannot be undone.
            """
        )
    }

    func repairDuplicateDays() {
        guard isRepairInProgress == false else {
            return
        }
        isRepairInProgress = true

        Task {
            defer {
                isRepairInProgress = false
            }
            do {
                try await diaryActionService.repairDuplicateDays(
                    context: context
                )
            } catch {
                errorMessage = error.localizedDescription
                isErrorPresented = true
            }
        }
    }
}
