import SwiftData
import SwiftUI

struct DebugContentView<Model: PersistentModel>: View {
    @Query private var models: [Model]

    @Binding private var detail: Model?

    var body: some View {
        List {
            ForEach(models) { model in
                Button {
                    detail = model
                } label: {
                    rowLabel(for: model)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                withAnimation {
                    indexSet.forEach { index in
                        let model = models[index]
                        model.modelContext?.delete(model)
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
            Text(PhotoDisplayCopy.title(for: photo))
        case let photoObject as PhotoObject:
            Text(
                photoObject.photo.map { photo in
                    PhotoDisplayCopy.title(for: photo)
                } ?? ""
            )
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

#Preview(traits: .modifier(CookleSampleData())) {
    DebugContentView<Recipe>()
}
