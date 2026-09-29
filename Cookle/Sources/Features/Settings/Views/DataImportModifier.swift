import SwiftData
import SwiftUI

/// Presents the import flow for a pending export file.
struct DataImportModifier: ViewModifier {
    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService
    let isICloudEnabled: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $model.isImportPresented) {
                NavigationStack {
                    DataImportView(
                        model: model,
                        modelContainer: modelContainer,
                        settingsActionService: settingsActionService,
                        isICloudEnabled: isICloudEnabled
                    )
                }
                .id(model.pendingImport?.presentationID)
                .interactiveDismissDisabled()
                .alert(
                    Text("Cannot Import Data"),
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
}

private extension DataImportModifier {
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
}
