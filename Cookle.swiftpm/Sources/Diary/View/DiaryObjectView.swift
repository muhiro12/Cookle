import SwiftUI

struct DiaryObjectView: View {
    @Environment(DiaryObject.self) private var object

    var body: some View {
        List {
            Section("Type") {
                Text(object.type.title)
            }
            Section("Recipes") {
                ForEach(object.recipes) {
                    Text($0.name)
                }
            }
            Section("Diary") {
                Text(object.diary?.date.formatted(.dateTime.year().month().day()) ?? "")
            }
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        DiaryObjectView()
            .environment(preview.diaryObjects[0])
    }
}
