import SwiftUI

struct SettingsActionStatusAlertModifier: ViewModifier {
    @Bindable var model: SettingsScreenModel

    var isStatusPresentedBinding: Binding<Bool> {
        .init(
            get: {
                model.statusMessage != nil
            },
            set: { isPresented in
                if isPresented == false {
                    model.statusMessage = nil
                }
            }
        )
    }

    func body(content: Content) -> some View {
        content
            .alert(
                Text("Settings Action Complete"),
                isPresented: isStatusPresentedBinding
            ) {
                Button("OK", role: .cancel) {
                    model.statusMessage = nil
                }
            } message: {
                Text(model.statusMessage ?? "")
            }
    }
}
