import SwiftUI

struct DiaryObjectView: View {
    @Environment(DiaryObject.self) private var object

    var body: some View {
        List {
            Section("Recipe") {
                Text(object.recipe.name)
            }
            Section("Type") {
                Text(object.type.title)
            }
            Section("Order") {
                Text(object.order.description)
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
