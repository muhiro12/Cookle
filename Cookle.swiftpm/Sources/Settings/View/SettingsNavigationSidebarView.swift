//
//  SettingsNavigationSidebarView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI
import SwiftUtilities

struct SettingsNavigationSidebarView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.isPresented) private var isPresented

    @AppStorage(.isSubscribeOn) private var isSubscribeOn
    @AppStorage(.isICloudOn) private var isICloudOn

    @Binding private var sidebar: SettingsNavigationSidebar?

    @State private var isAlertPresented = false

    init(selection: Binding<SettingsNavigationSidebar?> = .constant(nil)) {
        self._sidebar = selection
    }

    var body: some View {
        List(selection: $sidebar) {
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
                Button("Delete All", systemImage: "trash", role: .destructive) {
                    isAlertPresented = true
                }
            } header: {
                Text("Manage")
            }
            Section {
                NavigationLink(value: SettingsNavigationSidebar.license) {
                    Text("Licenses")
                }
            }
        }
        .navigationTitle(Text("Settings"))
        .toolbar {
            if isPresented {
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

#Preview {
    CooklePreview { _ in
        SettingsNavigationSidebarView()
    }
}
