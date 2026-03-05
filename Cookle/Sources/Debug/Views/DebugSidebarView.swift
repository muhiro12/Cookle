import SwiftUI
import TipKit

struct DebugSidebarView: View {
    @Environment(\.modelContext)
    private var context
    @Environment(\.isPresented)
    private var isPresented
    @Environment(CookleTipController.self)
    private var tipController

    @AppStorage(.isDebugOn)
    private var isDebugOn

    @Binding private var content: DebugContent?

    @State private var previewStore = CooklePreviewStore()
    @State private var isCreatingPreviewDiaries = false
    @State private var isAlertPresented = false

    var body: some View {
        sidebarList
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
                    // Dismisses the confirmation dialog.
                } label: {
                    Text("Cancel")
                }
            } message: {
                Text("Are you really going to create Preview Diary?")
            }
    }

    var sidebarList: some View {
        List(selection: $content) {
            appStorageSection
            manageSection
            tipKitSection
            previewSection
            modelSection
        }
    }

    var appStorageSection: some View {
        Section {
            Toggle("Debug On", isOn: $isDebugOn)
        } header: {
            Text("AppStorage")
        }
    }

    var manageSection: some View {
        Section {
            Button("Create Preview Diaries", systemImage: "flask") {
                isAlertPresented = true
            }
            .disabled(isCreatingPreviewDiaries)
        } header: {
            Text("Manage")
        }
    }

    var tipKitSection: some View {
        Section("TipKit") {
            Button("Reset Tips") {
                do {
                    try tipController.resetTips()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            Button("Show All Tips For Testing") {
                Tips.showAllTipsForTesting()
            }
            Button("Hide All Tips For Testing") {
                Tips.hideAllTipsForTesting()
            }
        }
    }

    var previewSection: some View {
        Section {
            NavigationLink(value: DebugContent.preview) {
                Text("Previews")
            }
        } header: {
            Text("Preview")
        }
    }

    var modelSection: some View {
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

    init(selection: Binding<DebugContent?> = .constant(nil)) {
        _content = selection
    }

    @MainActor
    private func createPreviewDiaries() async {
        isCreatingPreviewDiaries = true
        defer {
            isCreatingPreviewDiaries = false
        }

        _ = await previewStore.createPreviewDiariesWithRemoteImages(context)
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        DebugSidebarView()
    }
}
