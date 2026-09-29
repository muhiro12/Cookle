#if DEBUG
import Foundation
import SwiftData

extension SettingsScreenModel {
    /// Opens a reproducible review over capture mode's isolated sample store.
    func prepareCaptureImportIfNeeded(context: ModelContext) async {
        guard CookleCaptureConfiguration.isEnabled,
              CookleCaptureConfiguration.screen == .backupImport else {
            return
        }
        do {
            let package = try await DataMaintenanceOperations.archivePackage(from: context)
            guard var manifest = try JSONSerialization.jsonObject(with: package.manifestData) as? [String: Any],
                  var recipes = manifest["recipes"] as? [[String: Any]],
                  var diaries = manifest["diaries"] as? [[String: Any]],
                  recipes.isEmpty == false, diaries.isEmpty == false else {
                return
            }
            recipes[0]["note"] = "Backup recipe note for import review"
            diaries[0]["note"] = "Backup diary note for import review"
            manifest["recipes"] = recipes
            manifest["diaries"] = diaries
            let archive = try DataMaintenanceOperations.validatedArchive(
                from: .init(
                    manifestData: JSONSerialization.data(withJSONObject: manifest),
                    photoFiles: package.photoFiles
                )
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
