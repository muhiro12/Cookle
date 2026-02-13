//
//  DiaryView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftData
import SwiftUI

struct DiaryView: View {
    @Environment(Diary.self) private var diary

    @Binding private var recipe: Recipe?

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }

    var body: some View {
        List(selection: $recipe) {
            ForEach(DiaryObjectType.allCases) { type in
                if let recipes = diary.objects?
                    .filter(
                        {
                            $0.type == type
                        }
                    )
                    .sorted()
                    .compactMap(\.recipe),
                   recipes.isNotEmpty {
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
            Section {
                EditDiaryButton()
                DeleteDiaryButton()
            } header: {
                Spacer()
            }
        }
        .navigationTitle(diary.date.formatted(.dateTime.year().month().day().weekday()))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                EditDiaryButton()
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var diaries: [Diary]
    NavigationStack {
        DiaryView()
            .environment(diaries[0])
    }
}
