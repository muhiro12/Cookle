import SwiftUI
import SwiftUtilities

struct SettingsNavigationView: View {
    @Environment(\.modelContext) private var context

    @AppStorage(.isSubscribeOn) private var isSubscribeOn
    @AppStorage(.isICloudOn) private var isICloudOn

    @State private var isAlertPresented = false

    var body: some View {
        NavigationStack {
            List {
                if isSubscribeOn {
                    Section {
                        Toggle("iCloud On", isOn: $isICloudOn)
                    } header: {
                        Text("Settings")
                    }
                } else {
                    StoreSection()
                }
                Section {
                    NavigationLink {
                        LicenseView()
                    } label: {
                        Text(("Licenses"))
                    }
                }
                Section {
                    Button("Delete All", systemImage: "trash", role: .destructive) {
                        isAlertPresented = true
                    }
                } header: {
                    Text("Manage")
                }
            }
            .navigationTitle(Text("Settings"))
            .toolbar {
                ToolbarItem {
                    CloseButton()
                }
            }
            .alert(Text("Are you sure you want to delete all data?"),
                   isPresented: $isAlertPresented) {
                Button(role: .destructive) {
                    withAnimation {
                        do {
                            try context.delete(model: Diary.self)
                            try context.delete(model: DiaryObject.self)
                            try context.delete(model: Recipe.self)
                            try context.delete(model: Ingredient.self)
                            try context.delete(model: IngredientObject.self)
                            try context.delete(model: Category.self)
                            try context.delete(model: Photo.self)
                            try context.delete(model: PhotoObject.self)
                        } catch {
                            assertionFailure(error.localizedDescription)
                        }
                    }
                } label: {
                    Text("Delete")
                }
                Button(role: .cancel) {
                } label: {
                    Text("Cancel")
                }
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        SettingsNavigationView()
    }
}
