import SwiftData
import SwiftUI

struct DebugContentView<Model: PersistentModel>: View {
    @Environment(\.modelContext)
    private var context

    @Query private var models: [Model]

    @Binding private var detail: Model?

    var body: some View {
        List(selection: $detail) {
            ForEach(models) { model in
                NavigationLink(value: model) {
                    rowLabel(for: model)
                }
            }
            .onDelete { indexSet in
                withAnimation {
                    indexSet.forEach { index in
                        models[index].delete()
                    }
                }
            }
        }
        .navigationTitle(Text("Content"))
    }

    init(selection: Binding<Model?> = .constant(nil)) {
        _detail = selection
    }
}

private extension DebugContentView {
    @ViewBuilder
    func rowLabel(for model: Model) -> some View {
        switch model {
        case let diary as Diary:
            Text(diary.date.formatted(.dateTime.year().month().day()))
        case let diaryObject as DiaryObject:
            Text(diaryObject.type?.title ?? "")
        case let recipe as Recipe:
            Text(recipe.name)
        case let photo as Photo:
            Text(photo.title)
        case let photoObject as PhotoObject:
            Text(photoObject.photo?.title ?? "")
        case let ingredient as Ingredient:
            Text(ingredient.value)
        case let ingredientObject as IngredientObject:
            Text((ingredientObject.ingredient?.value ?? "") + " " + ingredientObject.amount)
        case let category as Category:
            Text(category.value)
        default:
            EmptyView()
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    DebugContentView<Recipe>()
}
