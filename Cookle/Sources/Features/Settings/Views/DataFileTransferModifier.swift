import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DataFileTransferModifier: ViewModifier {
    private struct ImportRequest: Identifiable {
        let id = UUID()
        let url: URL
    }

    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService
    @State private var importRequest: ImportRequest?

    func body(content: Content) -> some View {
        content
            .fileExporter(
                isPresented: $model.isDataExporterPresented,
                document: model.exportDocument,
                contentTypes: [
                    .cookleData
                ],
                defaultFilename: model.exportFilename
            ) { result in
                model.exportDocument = nil
                if case .failure(let error) = result {
                    model.errorMessage = error.localizedDescription
                }
            } onCancellation: {
                model.exportDocument = nil
            }
            .fileImporter(
                isPresented: $model.isDataImporterPresented,
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
                await prepareRequestedDataImport()
            }
            .onDisappear {
                importRequest = nil
            }
    }
}

private extension DataFileTransferModifier {
    func prepareRequestedDataImport() async {
        guard let importRequest else {
            return
        }
        await model.prepareDataImport(
            from: importRequest.url,
            modelContainer: modelContainer,
            settingsActionService: settingsActionService
        )
        if self.importRequest?.id == importRequest.id {
            self.importRequest = nil
        }
    }
}
