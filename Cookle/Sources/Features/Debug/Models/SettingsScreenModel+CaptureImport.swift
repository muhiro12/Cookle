#if DEBUG
import Foundation
import SwiftData

extension SettingsScreenModel {
    /// Opens a reproducible review over capture mode's isolated sample store.
    func prepareCaptureImportIfNeeded(context: ModelContext) {
        guard CookleCaptureConfiguration.isEnabled,
              CookleCaptureConfiguration.screen == .backupImport else {
            return
        }
        do {
            let data = try DataMaintenanceOperations.encodedArchive(from: context)
            guard var wire = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  var recipes = wire["recipes"] as? [[String: Any]],
                  var diaries = wire["diaries"] as? [[String: Any]],
                  recipes.isEmpty == false, diaries.isEmpty == false else {
                return
            }
            recipes[0]["note"] = "Backup recipe note for import review"
            diaries[0]["note"] = "Backup diary note for import review"
            wire["recipes"] = recipes
            wire["diaries"] = diaries
            let archive = try DataMaintenanceOperations.validatedArchive(
                from: JSONSerialization.data(withJSONObject: wire)
            )
            pendingImport = .init(
                archive: archive,
                review: try DataMaintenanceOperations.importReview(for: archive, context: context)
            )
            isImportReviewPresented = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
