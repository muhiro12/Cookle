import Foundation
import SwiftData

extension SettingsScreenModel {
    /// Replaces all current data with the pending complete-library file.
    func replaceWithPendingImport(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async {
        guard var pendingImport,
              pendingImport.canReplace,
              beginManageAction() else {
            return
        }
        defer {
            isManageActionInProgress = false
        }

        importErrorMessage = nil
        do {
            let summary = try await settingsActionService.replaceAllData(
                with: pendingImport.archive,
                review: pendingImport.replacementReview,
                modelContainer: modelContainer
            )
            finishImport(message: Self.replacementMessage(summary))
        } catch CookleDataImportError.replacementReviewChanged {
            do {
                pendingImport.review = try settingsActionService.importReview(
                    for: pendingImport.archive,
                    modelContainer: modelContainer
                )
                pendingImport.replacementReview = try settingsActionService.replacementReview(
                    for: pendingImport.archive,
                    modelContainer: modelContainer
                )
                pendingImport.selections = .init()
                pendingImport.presentationID = UUID()
                pendingImport.isReviewRefreshed = true
                self.pendingImport = pendingImport
            } catch {
                importErrorMessage = error.localizedDescription
            }
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }
}
