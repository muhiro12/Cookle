import SwiftUI

struct AddDiaryButton: View {
    @Environment(CookleTipController.self)
    private var tipController

    @State private var isPresented = false

    private let action: (() -> Void)?

    var body: some View {
        Button {
            tipController.donateDidOpenDiaryForm()

            if let action {
                action()
            } else {
                isPresented = true
            }
        } label: {
            Label {
                Text("Add")
            } icon: {
                Image(systemName: "book")
            }
        }
        .sheet(isPresented: $isPresented) {
            DiaryFormNavigationView()
        }
    }

    init(action: (() -> Void)? = nil) {
        self.action = action
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    AddDiaryButton()
}
