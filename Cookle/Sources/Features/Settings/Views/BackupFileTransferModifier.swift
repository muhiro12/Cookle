import SwiftUI
import UniformTypeIdentifiers

struct BackupFileTransferModifier: ViewModifier {
    @Bindable var model: SettingsScreenModel

    let settingsActionService: SettingsActionService

    func body(content: Content) -> some View {
        content
            .fileExporter(
                isPresented: $model.isBackupExporterPresented,
                document: model.backupDocument,
                contentType: .json,
                defaultFilename: model.backupFilename
            ) { result in
                if case .failure(let error) = result {
                    model.errorMessage = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $model.isBackupImporterPresented,
                allowedContentTypes: CookleDataArchiveDocument.readableContentTypes
            ) { result in
                switch result {
                case .success(let url):
                    model.prepareBackupRestore(
                        from: url,
                        settingsActionService: settingsActionService
                    )
                case .failure(let error):
                    model.errorMessage = error.localizedDescription
                }
            }
    }
}
