import SwiftUI
import SwiftUtilities

struct DebugSidebarView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.isPresented) private var isPresented

    @AppStorage(.isDebugOn) private var isDebugOn

    @Binding private var content: DebugContent?

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
        .alert("Create Preview Diaries", isPresented: $isAlertPresented) {
            Button(role: .destructive) {
                withAnimation {
                    _ = CooklePreviewStore().createPreviewDiaries(context)
                }
            } label: {
                Text("Create")
            }
            Button(role: .cancel) {
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("Are you really going to create Preview Diary?")
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            DebugSidebarView()
        }
    }
}
