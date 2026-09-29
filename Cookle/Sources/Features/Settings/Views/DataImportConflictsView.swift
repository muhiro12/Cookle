import MHUI
import SwiftData
import SwiftUI

/// Lists every item that differs between an export file and current data so
/// the person can choose how each one is imported.
///
/// Import stays disabled until each conflict has a compatible choice;
/// going back leaves current data unchanged.
struct DataImportConflictsView: View {
    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService

    var body: some View {
        Form {
            if let pendingImport = model.pendingImport {
                recipeConflictsSection(pendingImport.review)
                diaryConflictsSection(pendingImport.review)
                if pendingImport.hasIncompatibleChoices {
                    Section {
                        Text(
                            """
                            A current recipe cannot be replaced by more than one recipe from the file, \
                            or be kept and replaced at once. Review the recipe choices.
                            """
                        )
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .mhFormChrome(.content)
        .disabled(model.isManageActionInProgress)
        .navigationTitle(Text("Choose for Each Item"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Import") {
                    Task {
                        await model.importPendingSelections(
                            modelContainer: modelContainer,
                            settingsActionService: settingsActionService
                        )
                    }
                }
                .disabled(
                    model.isManageActionInProgress
                        || model.pendingImport?.isReadyToImport != true
                )
            }
        }
    }
}

private extension DataImportConflictsView {
    @ViewBuilder
    func recipeConflictsSection(_ review: CookleDataImportReview) -> some View {
        if review.recipeConflicts.isEmpty == false {
            Section {
                ForEach(review.recipeConflicts) { conflict in
                    NavigationLink {
                        DataImportRecipeConflictView(
                            conflict: conflict,
                            choice: recipeChoice(for: conflict.id)
                        )
                    } label: {
                        conflictRow(
                            title: conflict.backup.name,
                            status: DataImportChoiceCopy.status(
                                of: model.pendingImport?.selections.recipeChoices[conflict.id],
                                in: conflict
                            )
                        )
                    }
                }
            } header: {
                Text("Recipe Conflicts")
            } footer: {
                Text(
                    """
                    These recipes in the file match current recipe names. \
                    Compare the versions and choose which to keep.
                    """
                )
            }
        }
    }

    @ViewBuilder
    func diaryConflictsSection(_ review: CookleDataImportReview) -> some View {
        if review.diaryConflicts.isEmpty == false {
            Section {
                ForEach(review.diaryConflicts) { conflict in
                    NavigationLink {
                        DataImportDiaryConflictView(
                            conflict: conflict,
                            calendar: review.calendar,
                            choice: diaryChoice(for: conflict.id)
                        )
                    } label: {
                        conflictRow(
                            title: DataImportChoiceCopy.day(conflict.day, calendar: review.calendar),
                            status: DataImportChoiceCopy.status(
                                of: model.pendingImport?.selections.diaryChoices[conflict.id]
                            )
                        )
                    }
                }
            } header: {
                Text("Diary Conflicts")
            } footer: {
                Text("These days already have a different diary.")
            }
        }
    }

    func conflictRow(title: String, status: String?) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .mhRowTitle()
            if let status {
                Text(status)
                    .mhRowSupporting()
            } else {
                Label("Choose an option", systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    func recipeChoice(for conflictID: String) -> Binding<CookleDataRecipeImportChoice?> {
        .init(
            get: {
                model.pendingImport?.selections.recipeChoices[conflictID]
            },
            set: { choice in
                model.pendingImport?.selections.recipeChoices[conflictID] = choice
            }
        )
    }

    func diaryChoice(for conflictID: String) -> Binding<CookleDataDiaryImportChoice?> {
        .init(
            get: {
                model.pendingImport?.selections.diaryChoices[conflictID]
            },
            set: { choice in
                model.pendingImport?.selections.diaryChoices[conflictID] = choice
            }
        )
    }
}
