import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct BackupFileTransferModifier: ViewModifier {
    private struct ImportRequest: Identifiable {
        let id = UUID()
        let url: URL
    }

    @Bindable var model: SettingsScreenModel

    let settingsActionService: SettingsActionService
    @State private var importRequest: ImportRequest?

    func body(content: Content) -> some View {
        content
            .fileExporter(
                isPresented: $model.isBackupExporterPresented,
                document: model.backupDocument,
                contentTypes: [
                    .cookleBackup
                ],
                defaultFilename: model.backupFilename
            ) { result in
                model.backupDocument = nil
                if case .failure(let error) = result {
                    model.errorMessage = error.localizedDescription
                }
            } onCancellation: {
                model.backupDocument = nil
            }
            .fileImporter(
                isPresented: $model.isBackupImporterPresented,
                allowedContentTypes: CookleDataArchiveDocument.importableContentTypes
            ) { result in
                switch result {
                case .success(let url):
                    importRequest = .init(
                        url: url
                    )
                case .failure(let error):
                    model.errorMessage = error.localizedDescription
                }
            }
            .task(id: importRequest?.id) {
                await prepareRequestedBackupImport()
            }
            .onDisappear {
                importRequest = nil
            }
    }
}

private extension BackupFileTransferModifier {
    func prepareRequestedBackupImport() async {
        guard let importRequest else {
            return
        }
        await model.prepareBackupRestore(
            from: importRequest.url,
            settingsActionService: settingsActionService
        )
        if self.importRequest?.id == importRequest.id {
            self.importRequest = nil
        }
    }
}
