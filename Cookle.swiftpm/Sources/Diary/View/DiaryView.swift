//
//  DiaryView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI

struct DiaryView: View {
    @Environment(Diary.self) private var diary

    @Binding private var selection: Recipe?

    init(selection: Binding<Recipe?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Section("Date") {
                Text(diary.date.formatted(.dateTime.year().month().day()))
            }
            if let breakfasts = diary.objects?
                .filter({ $0.type == .breakfast })
                .sorted(by: { $0.order < $1.order })
                .compactMap({ $0.recipe }),
               breakfasts.isNotEmpty {
                Section("Breakfast") {
                    ForEach(breakfasts, id: \.self) { recipe in
                        Text(recipe.name)
                    }
                }
            }
            if let lunches = diary.objects?
                .filter({ $0.type == .lunch })
                .sorted(by: { $0.order < $1.order })
                .compactMap({ $0.recipe }),
               lunches.isNotEmpty {
                Section("Lunch") {
                    ForEach(lunches, id: \.self) { recipe in
                        Text(recipe.name)
                    }
                }
            }
            if let dinners = diary.objects?
                .filter({ $0.type == .dinner })
                .sorted(by: { $0.order < $1.order })
                .compactMap({ $0.recipe }),
               dinners.isNotEmpty {
                Section("Dinner") {
                    ForEach(dinners, id: \.self) { recipe in
                        Text(recipe.name)
                    }
                }
            }
            if diary.note.isNotEmpty {
                Section("Note") {
                    Text(diary.note)
                }
            }
            Section("Created At") {
                Text(diary.createdTimestamp.formatted(.dateTime.year().month().day()))
            }
            Section("Updated At") {
                Text(diary.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            }
        }
        .navigationTitle(diary.date.formatted(.dateTime.year().month().day()))
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
            DiaryView(selection: .constant(nil))
                .environment(preview.diaries[0])
        }
    }
}
