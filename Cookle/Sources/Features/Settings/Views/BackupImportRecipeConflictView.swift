import MHUI
import SwiftUI

/// Compares a backup recipe with the current recipes that share its name and
/// records how it should be imported.
struct BackupImportRecipeConflictView: View {
    let conflict: CookleDataImportReview.RecipeConflict

    @Binding var choice: CookleDataRecipeImportChoice?

    var body: some View {
        Form {
            choiceSection
            BackupImportRecipeSnapshotSection(
                title: String(localized: "Backup Version"),
                snapshot: conflict.backup,
                footer: nil
            )
            ForEach(Array(conflict.candidates.enumerated()), id: \.element.id) { index, candidate in
                BackupImportRecipeSnapshotSection(
                    title: conflict.candidates.count > 1
                        ? String(localized: "Current Recipe \(index + 1)")
                        : String(localized: "Current Recipe"),
                    snapshot: candidate.recipe,
                    footer: candidateFooter(candidate)
                )
            }
        }
        .mhFormChrome(.content)
        .navigationTitle(conflict.backup.name)
    }
}

private extension BackupImportRecipeConflictView {
    var choiceSection: some View {
        Section {
            ForEach(conflict.candidates) { candidate in
                BackupImportChoiceRow(
                    title: BackupImportChoiceCopy.keepCurrentTitle(for: candidate.id, in: conflict),
                    isSelected: choice == .keepCurrent(candidate.id)
                ) {
                    choice = .keepCurrent(candidate.id)
                }
                BackupImportChoiceRow(
                    title: BackupImportChoiceCopy.useBackupTitle(for: candidate.id, in: conflict),
                    isSelected: choice == .useBackup(candidate.id)
                ) {
                    choice = .useBackup(candidate.id)
                }
            }
            BackupImportChoiceRow(
                title: String(localized: "Keep Both"),
                isSelected: choice == .keepBoth
            ) {
                choice = .keepBoth
            }
        } header: {
            Text("Import Choice")
        } footer: {
            Text(
                """
                    Keeping a current recipe ignores the backup version, and backup diaries that use it \
                    show the current recipe. Replacing updates that current recipe, so every diary meal \
                    that shows it shows the backup content. Keeping both adds the backup version as a \
                    separate recipe.
                    """
            )
        }
    }

    func candidateFooter(_ candidate: CookleDataImportReview.RecipeCandidate) -> String {
        let usage = String(localized: "Shown in \(candidate.diaryMealRowCount) diary meals.")
        guard candidate.isIdenticalToBackup else {
            return usage
        }

        return usage + " " + String(localized: "Identical to the backup version.")
    }
}
