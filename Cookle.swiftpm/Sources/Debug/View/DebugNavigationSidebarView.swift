import SwiftUI
import SwiftUtilities

struct DebugNavigationSidebarView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage(.isDebugOn) private var isDebugOn

    @Binding private var selection: DebugContent?

    @State private var isAlertPresented = false

    init(selection: Binding<DebugContent?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                Toggle("Debug On", isOn: $isDebugOn)
            }
            Section {
                ForEach(DebugContent.allCases, id: \.self) { content in
                    switch content {
                    case .diary:
                        Text("Diaries")
                    case .diaryObject:
                        Text("DiaryObjects")
                    case .recipe:
                        Text("Recipes")
                    case .ingredient:
                        Text("Ingredients")
                    case .ingredientObject:
                        Text("IngredientObjects")
                    case .category:
                        Text("Categories")
                    case .photo:
                        Text("Photos")
                    case .photoObject:
                        Text("PhotoObjects")
                    }
                }
            } header: {
                Text("Models")
            }
            Section {
                Button("Create Preview Diary", systemImage: "flask") {
                    isAlertPresented = true
                }
            } header: {
                Text("Manage")
            }
            StoreSection()
            AdvertisementSection(.medium)
            AdvertisementSection(.small)
        }
        .navigationTitle(Text("Debug"))
        .toolbar {
            ToolbarItem {
                CloseButton()
            }
        }
        .alert("Create Preview Diary", isPresented: $isAlertPresented) {
            Button(role: .destructive) {
                withAnimation {
                    _ = CooklePreviewStore().createPreviewDiary(context)
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
            DebugNavigationSidebarView(selection: .constant(nil))
        }
    }
}
