import SwiftUI

struct DebugSidebarView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.isPresented) private var isPresented

    @AppStorage(.isDebugOn) private var isDebugOn

    @Binding private var content: DebugContent?

    @State private var previewStore = CooklePreviewStore()
    @State private var isCreatingPreviewDiaries = false
    @State private var isAlertPresented = false

    init(selection: Binding<DebugContent?> = .constant(nil)) {
        _content = selection
    }

    var body: some View {
        List(selection: $content) {
            Section {
                Toggle("Debug On", isOn: $isDebugOn)
            } header: {
                Text("AppStorage")
            }
            Section {
                Button("Create Preview Diaries", systemImage: "flask") {
                    isAlertPresented = true
                }
                .disabled(isCreatingPreviewDiaries)
            } header: {
                Text("Manage")
            }
            Section {
                NavigationLink(value: DebugContent.preview) {
                    Text("Previews")
                }
            } header: {
                Text("Preview")
            }
            Section {
                NavigationLink(value: DebugContent.diary) {
                    Text("Diaries")
                }
                NavigationLink(value: DebugContent.diaryObject) {
                    Text("DiaryObjects")
                }
                NavigationLink(value: DebugContent.recipe) {
                    Text("Recipes")
                }
                NavigationLink(value: DebugContent.photo) {
                    Text("Photos")
                }
                NavigationLink(value: DebugContent.photoObject) {
                    Text("PhotoObjects")
                }
                NavigationLink(value: DebugContent.ingredient) {
                    Text("Ingredients")
                }
                NavigationLink(value: DebugContent.ingredientObject) {
                    Text("IngredientObjects")
                }
                NavigationLink(value: DebugContent.category) {
                    Text("Categories")
                }
            } header: {
                Text("Model")
            }
        }
        .navigationTitle(Text("Debug"))
        .toolbar {
            ToolbarItem {
                CloseButton()
                    .hidden(!isPresented)
            }
        }
        .confirmationDialog(
            Text("Create Preview Diaries"),
            isPresented: $isAlertPresented
        ) {
            Button(role: .destructive) {
                guard !isCreatingPreviewDiaries else {
                    return
                }
                Task {
                    await createPreviewDiaries()
                }
            } label: {
                Text("Create")
            }
            .disabled(isCreatingPreviewDiaries)
            Button(role: .cancel) {
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("Are you really going to create Preview Diary?")
        }
    }

    @MainActor
    private func createPreviewDiaries() async {
        isCreatingPreviewDiaries = true
        defer {
            isCreatingPreviewDiaries = false
        }

        do {
            _ = try await previewStore.createPreviewDiariesWithRemoteImages(context)
        } catch {
            assertionFailure("Failed to create preview diaries: \(error.localizedDescription)")
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        DebugSidebarView()
    }
}
