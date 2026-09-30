import MHUI
import SwiftData
import SwiftUI

struct DebugContentView<Model: PersistentModel>: View {
    @Environment(\.modelContext)
    private var context
    @Environment(NotificationService.self)
    private var notificationService

    @Query private var models: [Model]

    @Binding private var detail: Model?

    @State private var isDeleting = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""
    @State private var detailIDToRestore: PersistentIdentifier?

    var body: some View {
        List {
            MHContainerContent {
                ForEach(models) { model in
                    Button {
                        detail = model
                    } label: {
                        rowLabel(for: model)
                            .cookleButtonRowContent()
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    delete(at: indexSet)
                }
            }
        }
        .mhListChrome(.native)
        .navigationTitle(Text("Content"))
        .disabled(isDeleting)
        .alert(Text("Cannot Delete"), isPresented: $isErrorPresented) {
            Button("OK", role: .cancel) {
                restoreDetailAfterError()
            }
        } message: {
            Text(errorMessage)
        }
    }

    init(selection: Binding<Model?> = .constant(nil)) {
        _detail = selection
    }
}

private extension DebugContentView {
    func delete(at offsets: IndexSet) {
        guard isDeleting == false else {
            return
        }
        let selectedModels = offsets.map { index in
            models[index]
        }
        let previousDetailID = detail?.persistentModelID
        if let detail, selectedModels.contains(where: { model in
            model.persistentModelID == detail.persistentModelID
        }) {
            self.detail = nil
        }
        isDeleting = true
        Task {
            defer {
                isDeleting = false
            }
            do {
                try await DebugActionService.delete(
                    context: context,
                    models: selectedModels,
                    notificationService: notificationService
                )
            } catch {
                detailIDToRestore = previousDetailID
                errorMessage = error.localizedDescription
                isErrorPresented = true
            }
        }
    }

    func restoreDetailAfterError() {
        defer {
            detailIDToRestore = nil
        }
        guard detail == nil, let detailIDToRestore else {
            return
        }
        detail = models.first { model in
            model.isDeleted == false && model.persistentModelID == detailIDToRestore
        }
    }

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
