//
//  SettingsSidebarView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI
import SwiftUtilities

struct SettingsSidebarView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.isPresented) private var isPresented

    @AppStorage(.isSubscribeOn) private var isSubscribeOn
    @AppStorage(.isICloudOn) private var isICloudOn

    @Binding private var content: SettingsContent?

    @State private var isAlertPresented = false

    init(selection: Binding<SettingsContent?> = .constant(nil)) {
        self._content = selection
    }

    var body: some View {
        List(selection: $content) {
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
                NavigationLink(value: SettingsContent.license) {
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
        SettingsSidebarView()
    }
}