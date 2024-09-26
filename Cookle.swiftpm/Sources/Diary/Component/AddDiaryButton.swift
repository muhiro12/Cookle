import SwiftUI

struct AddDiaryButton: View {
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label {
                Text("Add Diary")
            } icon: {
                Image(systemName: "book")
            }
        }
        .sheet(isPresented: $isPresented) {
            DiaryFormNavigationView()
        }
    }
}

#Preview {
    CooklePreview { _ in
        AddDiaryButton()
    }
}
