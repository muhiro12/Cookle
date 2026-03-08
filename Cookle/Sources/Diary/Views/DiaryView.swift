//
//  DiaryView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftData
import SwiftUI

struct DiaryView: View {
    @Environment(Diary.self)
    private var diary

    @Binding private var recipe: Recipe?

    var body: some View {
        List(selection: $recipe) {
            mealSections
            noteSection
            createdAtSection
            updatedAtSection
            actionSection
        }
        .navigationTitle(diary.date.formatted(.dateTime.year().month().day().weekday()))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                EditDiaryButton()
            }
        }
    }

    @ViewBuilder var mealSections: some View {
        ForEach(DiaryObjectType.allCases) { type in
            let recipes = mealRecipes(for: type)
            if recipes.isNotEmpty {
                Section {
                    ForEach(recipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeLabel()
                                .labelStyle(.titleAndLargeIcon)
                                .environment(recipe)
                        }
                    }
                } header: {
                    Text(type.title)
                }
            }
        }
    }

    @ViewBuilder var noteSection: some View {
        if diary.note.isNotEmpty {
            Section {
                Text(diary.note)
            } header: {
                Text("Note")
            }
        }
    }

    var createdAtSection: some View {
        Section {
            Text(diary.createdTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Created At")
        }
    }

    var updatedAtSection: some View {
        Section {
            Text(diary.modifiedTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Updated At")
        }
    }

    var actionSection: some View {
        Section {
            EditDiaryButton()
            DeleteDiaryButton()
        } header: {
            Spacer()
        }
    }

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }

    func mealRecipes(for type: DiaryObjectType) -> [Recipe] {
        diary.objects.orEmpty
            .filter { object in
                object.type == type
            }
            .sorted()
            .compactMap(\.recipe)
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var diaries: [Diary]
    NavigationStack {
        DiaryView()
            .environment(diaries[0])
    }
}
