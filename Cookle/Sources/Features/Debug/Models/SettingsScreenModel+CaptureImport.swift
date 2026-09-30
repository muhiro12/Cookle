#if DEBUG
import Foundation
import SwiftData

extension SettingsScreenModel {
    /// Opens a reproducible import over capture mode's isolated sample store.
    func prepareCaptureImportIfNeeded(context: ModelContext) async {
        guard CookleCaptureConfiguration.isEnabled,
              CookleCaptureConfiguration.screen == .dataImport else {
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
            recipes[0]["note"] = "Recipe note from the imported file"
            diaries[0]["note"] = "Diary note from the imported file"
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
                review: try DataMaintenanceOperations.importReview(for: archive, context: context),
                replacementReview: try DataMaintenanceOperations.replacementReview(for: archive, context: context)
            )
            isImportPresented = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
