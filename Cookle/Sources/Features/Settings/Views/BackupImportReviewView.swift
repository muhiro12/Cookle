import MHUI
import SwiftData
import SwiftUI

/// Reviews a backup before it merges into current data.
///
/// Warns that the backup is combined with current data, offers exporting the
/// current data first, and lists every conflict. Import stays disabled until
/// each conflict has a choice; cancelling leaves current data unchanged.
struct BackupImportReviewView: View {
    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService
    let isICloudEnabled: Bool

    @State private var exportDocument: CookleDataArchiveDocument?
    @State private var isExporterPresented = false
    @State private var isExportInProgress = false

    var body: some View {
        Form {
            if let pendingImport = model.pendingImport {
                warningSection
                if pendingImport.isReviewRefreshed {
                    Section {
                        Label(
                            """
                            Your data changed after this review was prepared. The review was updated; \
                            choose again for any conflict that changed.
                            """,
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }
                }
                summarySection(pendingImport.review)
                recipeConflictsSection(pendingImport.review)
                diaryConflictsSection(pendingImport.review)
                if pendingImport.hasIncompatibleChoices {
                    Section {
                        Text(
                            """
                            A current recipe cannot be replaced by multiple backup recipes or kept and \
                            replaced at once. \
                            Review the recipe choices.
                            """
                        )
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .mhFormChrome(.content)
        .disabled(model.isManageActionInProgress || isExportInProgress)
        .navigationTitle(Text("Review Import"))
        .toolbar {
            toolbarItems
        }
        .fileExporter(
            isPresented: $isExporterPresented,
            document: exportDocument,
            contentTypes: [
                .cookleBackup
            ],
            defaultFilename: model.backupFilename
        ) { result in
            exportDocument = nil
            if case .failure(let error) = result {
                model.importErrorMessage = error.localizedDescription
            }
        } onCancellation: {
            exportDocument = nil
        }
        .alert(
            Text("Cannot Import Backup"),
            isPresented: isImportErrorPresented
        ) {
            Button("OK", role: .cancel) {
                model.importErrorMessage = nil
            }
        } message: {
            Text(model.importErrorMessage ?? "")
        }
    }
}

private extension BackupImportReviewView {
    var isImportErrorPresented: Binding<Bool> {
        .init(
            get: {
                model.importErrorMessage != nil
            },
            set: { isPresented in
                if isPresented == false {
                    model.importErrorMessage = nil
                }
            }
        )
    }

    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                model.cancelPendingImport()
            }
            .disabled(model.isManageActionInProgress || isExportInProgress)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Import") {
                Task {
                    await model.importPendingBackup(
                        modelContainer: modelContainer,
                        settingsActionService: settingsActionService
                    )
                }
            }
            .disabled(
                model.isManageActionInProgress || isExportInProgress
                    || model.pendingImport?.isReadyToImport != true
            )
        }
    }

    var warningSection: some View {
        Section {
            Label(
                """
                Importing merges this backup into your current recipes, diaries, tags, and photos. \
                Nothing is removed unless you choose to replace a conflicting item.
                """,
                systemImage: "exclamationmark.triangle"
            )
            if isICloudEnabled {
                Text(
                    """
                    Imported changes sync to other devices using the same iCloud account, \
                    and deleting them later on this device does not restore those devices.
                    """
                )
                .foregroundStyle(.secondary)
            }
            Button("Export Current Data First", systemImage: "square.and.arrow.up") {
                Task {
                    await exportCurrentData()
                }
            }
        } header: {
            Text("Before You Import")
        } footer: {
            Text("Export a separate backup before importing. Importing does not provide automatic undo.")
        }
    }

    func summarySection(_ review: CookleDataImportReview) -> some View {
        Section {
            LabeledContent("New Recipes", value: review.newRecipeCount.formatted())
            LabeledContent("Unchanged Recipes", value: review.unchangedRecipeCount.formatted())
            LabeledContent("New Diary Days", value: review.newDiaryCount.formatted())
            LabeledContent("Unchanged Diary Days", value: review.unchangedDiaryCount.formatted())
        } header: {
            Text("Summary")
        } footer: {
            if review.hasConflicts {
                Text("Choose an option for every conflict below before importing.")
            } else {
                Text("Nothing in this backup conflicts with your current data.")
            }
        }
    }

    @ViewBuilder
    func recipeConflictsSection(_ review: CookleDataImportReview) -> some View {
        if review.recipeConflicts.isEmpty == false {
            Section {
                ForEach(review.recipeConflicts) { conflict in
                    NavigationLink {
                        BackupImportRecipeConflictView(
                            conflict: conflict,
                            choice: recipeChoice(for: conflict.id)
                        )
                    } label: {
                        conflictRow(
                            title: conflict.backup.name,
                            status: BackupImportChoiceCopy.status(
                                of: model.pendingImport?.selections.recipeChoices[conflict.id],
                                in: conflict
                            )
                        )
                    }
                }
            } header: {
                Text("Recipe Conflicts")
            } footer: {
                Text("These backup recipes match current recipe names. Compare the versions and choose which to keep.")
            }
        }
    }

    @ViewBuilder
    func diaryConflictsSection(_ review: CookleDataImportReview) -> some View {
        if review.diaryConflicts.isEmpty == false {
            Section {
                ForEach(review.diaryConflicts) { conflict in
                    NavigationLink {
                        BackupImportDiaryConflictView(
                            conflict: conflict,
                            calendar: review.calendar,
                            choice: diaryChoice(for: conflict.id)
                        )
                    } label: {
                        conflictRow(
                            title: BackupImportChoiceCopy.day(conflict.day, calendar: review.calendar),
                            status: BackupImportChoiceCopy.status(
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

    func exportCurrentData() async {
        isExportInProgress = true
        defer {
            isExportInProgress = false
        }

        do {
            exportDocument = .init(
                archivePackage: try await settingsActionService.exportBackupPackage(
                    modelContainer: modelContainer
                )
            )
            isExporterPresented = true
        } catch is CancellationError {
            exportDocument = nil
        } catch {
            model.importErrorMessage = error.localizedDescription
        }
    }
}
