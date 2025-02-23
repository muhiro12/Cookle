import SwiftUI

struct EditDiaryButton: View {
    @Environment(Diary.self) private var diary

    @State private var isPresented = false

    private let action: (() -> Void)?

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

    var body: some View {
        Button {
            if let action {
                action()
            } else {
                isPresented = true
            }
        } label: {
            Label {
                Text("Edit")
            } icon: {
                Image(systemName: "pencil")
            }
        }
        .sheet(isPresented: $isPresented) {
            DiaryFormNavigationView()
        }
    }
}

#Preview {
    CooklePreview { preview in
        EditDiaryButton()
            .environment(preview.diaries[0])
    }
}
