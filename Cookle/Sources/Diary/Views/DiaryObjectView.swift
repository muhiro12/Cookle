import SwiftData
import SwiftUI

struct DiaryObjectView: View {
    @Environment(DiaryObject.self) private var object

    var body: some View {
        List {
            Section {
                Text(object.recipe?.name ?? "")
            } header: {
                Text("Recipe")
            }
            Section {
                Text(object.type?.title ?? "")
            } header: {
                Text("Type")
            }
            Section {
                Text(object.order.description)
            } header: {
                Text("Order")
            }
            Section {
                Text(object.diary?.date.formatted(.dateTime.year().month().day()) ?? "")
            } header: {
                Text("Diary")
            }
            Section {
                Text(object.createdTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Created At")
            }
            Section {
                Text(object.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Updated At")
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var diaryObjects: [DiaryObject]
    DiaryObjectView()
        .environment(diaryObjects[0])
}
