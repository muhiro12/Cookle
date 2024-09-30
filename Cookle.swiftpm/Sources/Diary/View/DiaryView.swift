//
//  DiaryView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI

struct DiaryView: View {
    @Environment(Diary.self) private var diary

    @Binding private var recipe: Recipe?

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }

    var body: some View {
        List(selection: $recipe) {
            if let breakfasts = diary.objects?
                .filter({ $0.type == .breakfast })
                .sorted()
                .compactMap({ $0.recipe }),
               breakfasts.isNotEmpty {
                Section {
                    ForEach(breakfasts) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeLabel()
                                .labelStyle(.titleAndLargeIcon)
                                .environment(recipe)
                        }
                    }
                } header: {
                    Text("Breakfast")
                }
            }
            if let lunches = diary.objects?
                .filter({ $0.type == .lunch })
                .sorted()
                .compactMap({ $0.recipe }),
               lunches.isNotEmpty {
                Section {
                    ForEach(lunches) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeLabel()
                                .labelStyle(.titleAndLargeIcon)
                                .environment(recipe)
                        }
                    }
                } header: {
                    Text("Lunch")
                }
            }
            if let dinners = diary.objects?
                .filter({ $0.type == .dinner })
                .sorted()
                .compactMap({ $0.recipe }),
               dinners.isNotEmpty {
                Section {
                    ForEach(dinners) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeLabel()
                                .labelStyle(.titleAndLargeIcon)
                                .environment(recipe)
                        }
                    }
                } header: {
                    Text("Dinner")
                }
            }
            if diary.note.isNotEmpty {
                Section {
                    Text(diary.note)
                } header: {
                    Text("Note")
                }
            }
            Section {
                Text(diary.createdTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Created At")
            }
            Section {
                Text(diary.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Updated At")
            }
        }
        .navigationTitle(diary.date.formatted(.dateTime.year().month().day().weekday()))
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                DeleteDiaryButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                EditDiaryButton()
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        NavigationStack {
            DiaryView()
                .environment(preview.diaries[0])
        }
    }
}
