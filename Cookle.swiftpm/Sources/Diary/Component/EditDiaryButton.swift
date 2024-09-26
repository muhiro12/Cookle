import SwiftUI

struct EditDiaryButton: View {
    @Environment(Diary.self) private var diary

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label {
                Text("Edit \(diary.date.formatted(.dateTime.year().month().day()))")
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
