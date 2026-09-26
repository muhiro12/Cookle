import MHUI
import SwiftData
import SwiftUI

struct DiaryObjectView: View {
    @Environment(DiaryObject.self)
    private var object

    var body: some View {
        List {
            MHContainerContent {
                recipeSection
                typeSection
                orderSection
                diarySection
                createdAtSection
                updatedAtSection
            }
        }
        .mhListChrome(.native)
    }

    var recipeSection: some View {
        Section {
            Text(object.recipe?.name ?? "")
        } header: {
            Text("Recipe")
        }
    }

    var typeSection: some View {
        Section {
            Text(object.type?.title ?? "")
        } header: {
            Text("Type")
        }
    }

    var orderSection: some View {
        Section {
            Text(object.order.description)
        } header: {
            Text("Order")
        }
    }

    var diarySection: some View {
        Section {
            Text(object.diary?.date.formatted(.dateTime.year().month().day()) ?? "")
        } header: {
            Text("Diary")
        }
    }

    var createdAtSection: some View {
        Section {
            Text(object.createdTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Created At")
        }
    }

    var updatedAtSection: some View {
        Section {
            Text(object.modifiedTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Updated At")
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var diaryObjects: [DiaryObject]
    DiaryObjectView()
        .environment(diaryObjects[0])
}
