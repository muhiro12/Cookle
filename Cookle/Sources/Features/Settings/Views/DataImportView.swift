import MHUI
import SwiftData
import SwiftUI

/// Summarizes a validated export file and lets the person choose how to import it.
///
/// With no current data, everything in the file is added. Otherwise the person
/// replaces current data with a complete-library file, merges the file so
/// matching items take its content, or chooses for each differing item.
/// Exporting current data first is offered for every method.
struct DataImportView: View {
    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService
    let isICloudEnabled: Bool

    @State private var exportDocument: CookleDataArchiveDocument?
    @State private var isExporterPresented = false
    @State private var isExportInProgress = false
    @State private var isMergeConfirmationPresented = false
    @State private var isReplaceConfirmationPresented = false

    var body: some View {
        form
            .mhFormChrome(.content)
            .disabled(isBusy)
            .navigationTitle(Text("Import Data"))
            .toolbar {
                toolbarItems
            }
            .fileExporter(
                isPresented: $isExporterPresented,
                document: exportDocument,
                contentTypes: [
                    .cookleData
                ],
                defaultFilename: model.exportFilename
            ) { result in
                exportDocument = nil
                if case .failure(let error) = result {
                    model.importErrorMessage = error.localizedDescription
                }
            } onCancellation: {
                exportDocument = nil
            }
            .alert(
                Text("Merge This File?"),
                isPresented: $isMergeConfirmationPresented
            ) {
                mergeConfirmationActions
            } message: {
                mergeConfirmationMessage
            }
            .alert(
                Text("Replace All Data?"),
                isPresented: $isReplaceConfirmationPresented
            ) {
                replaceConfirmationActions
            } message: {
                replaceConfirmationMessage
            }
    }
}

private extension DataImportView {
    var isBusy: Bool {
        model.isManageActionInProgress || isExportInProgress
    }

    var form: some View {
        Form {
            if let pendingImport = model.pendingImport {
                if pendingImport.isReviewRefreshed {
                    Section {
                        Label(
                            """
                            Your data changed after this file was reviewed. The summary was updated; \
                            choose how to import again.
                            """,
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }
                }
                summarySection(pendingImport)
                if pendingImport.needsMethodChoice {
                    exportFirstSection
                    methodSection(pendingImport)
                }
            }
        }
    }

    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                model.cancelPendingImport()
            }
            .disabled(isBusy)
        }
        if model.pendingImport?.needsMethodChoice == false {
            ToolbarItem(placement: .confirmationAction) {
                Button("Import") {
                    Task {
                        await model.mergePendingImport(
                            modelContainer: modelContainer,
                            settingsActionService: settingsActionService
                        )
                    }
                }
                .disabled(isBusy)
            }
        }
    }

    var exportFirstSection: some View {
        Section {
            Button("Export Current Data First", systemImage: "square.and.arrow.up") {
                Task {
                    await exportCurrentData()
                }
            }
            if isICloudEnabled {
                Text("Imported changes sync to other devices using the same iCloud account.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Before You Import")
        } footer: {
            Text("Importing can't be undone. Export your current data first so you can return to it.")
        }
    }

    var mergeMethodButton: some View {
        Button {
            isMergeConfirmationPresented = true
        } label: {
            methodLabel(
                title: "Merge",
                detail: "Add new items and update matching items with the file's content.",
                systemImage: "arrow.triangle.merge"
            )
        }
    }

    var chooseForEachItemLink: some View {
        NavigationLink {
            DataImportConflictsView(
                model: model,
                modelContainer: modelContainer,
                settingsActionService: settingsActionService
            )
        } label: {
            methodLabel(
                title: "Choose for Each Item",
                detail: "Compare each item that differs and choose which version to keep.",
                systemImage: "checklist"
            )
        }
    }

    var replaceMethodButton: some View {
        Button(role: .destructive) {
            isReplaceConfirmationPresented = true
        } label: {
            methodLabel(
                title: "Replace",
                detail: "Delete all current data and use only the file's content.",
                systemImage: "arrow.2.squarepath"
            )
        }
    }

    @ViewBuilder var mergeConfirmationActions: some View {
        Button("Merge") {
            Task {
                await model.mergePendingImport(
                    modelContainer: modelContainer,
                    settingsActionService: settingsActionService
                )
            }
        }
        Button("Cancel", role: .cancel) {
            // Dismisses the alert.
        }
    }

    var mergeConfirmationMessage: some View {
        Text(
            """
            New items are added, and items with the same recipe name or diary day are updated \
            with the file's content. Items that are only on this device stay. This can't be undone.
            """
        )
    }

    @ViewBuilder var replaceConfirmationActions: some View {
        Button("Replace", role: .destructive) {
            Task {
                await model.replaceWithPendingImport(
                    modelContainer: modelContainer,
                    settingsActionService: settingsActionService
                )
            }
        }
        Button("Cancel", role: .cancel) {
            // Dismisses the alert.
        }
    }

    @ViewBuilder var replaceConfirmationMessage: some View {
        if isICloudEnabled {
            Text(
                """
                This deletes all current recipes, diaries, tags, and photos and replaces them with \
                the file's content. The change syncs to other devices using the same iCloud account. \
                This can't be undone.
                """
            )
        } else {
            Text(
                """
                This deletes all recipes, diaries, tags, and photos on this device and replaces them \
                with the file's content. This can't be undone.
                """
            )
        }
    }

    func summarySection(_ pendingImport: PendingDataImport) -> some View {
        let review = pendingImport.review
        return Section {
            LabeledContent("New Recipes", value: review.newRecipeCount.formatted())
            if pendingImport.needsMethodChoice {
                LabeledContent("Recipes That Differ", value: review.recipeConflicts.count.formatted())
                LabeledContent("Unchanged Recipes", value: review.unchangedRecipeCount.formatted())
            }
            LabeledContent("New Diary Days", value: review.newDiaryCount.formatted())
            if pendingImport.needsMethodChoice {
                LabeledContent("Diary Days That Differ", value: review.diaryConflicts.count.formatted())
                LabeledContent("Unchanged Diary Days", value: review.unchangedDiaryCount.formatted())
            }
        } header: {
            Text("Summary")
        } footer: {
            if pendingImport.needsMethodChoice == false {
                Text("You have no data on this device yet, so everything in this file will be added.")
            } else if review.hasConflicts {
                Text("Items differ when a recipe name or diary day matches but the content does not.")
            } else {
                Text("Nothing in this file differs from your current data.")
            }
        }
    }

    func methodSection(_ pendingImport: PendingDataImport) -> some View {
        Section {
            mergeMethodButton
            if pendingImport.review.hasConflicts {
                chooseForEachItemLink
            }
            if pendingImport.canReplace {
                replaceMethodButton
            }
        } header: {
            Text("How to Import")
        } footer: {
            if pendingImport.canReplace == false {
                Text("This file contains only part of a library, so it can be merged but can't replace your data.")
            }
        }
    }

    func methodLabel(
        title: LocalizedStringKey,
        detail: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        Label {
            VStack(alignment: .leading) {
                Text(title)
                    .mhRowTitle()
                Text(detail)
                    .mhRowSupporting()
            }
        } icon: {
            Image(systemName: systemImage)
                .accessibilityHidden(true)
        }
    }

    func exportCurrentData() async {
        isExportInProgress = true
        defer {
            isExportInProgress = false
        }

        do {
            exportDocument = .init(
                archivePackage: try await settingsActionService.exportDataPackage(
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
