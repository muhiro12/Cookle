import SwiftUI

struct EditDiaryButton: View {
    @Environment(Diary.self) private var diary

    @State private var isPresented = false

    var body: some View {
        Button("Edit Diary", systemImage: "pencil") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            DiaryFormNavigationView()
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        EditDiaryButton()
            .environment(preview.diaries[0])
    }
}
