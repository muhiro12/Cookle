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
            Section("Breakfast") {
                ForEach(diary.objects.filter { $0.type == .breakfast }.sorted { $0.order < $1.order }.map { $0.recipe }, id: \.self) { recipe in
                    Text(recipe.name)
                }
            }
            Section("Lunch") {
                ForEach(diary.objects.filter { $0.type == .lunch }.sorted { $0.order < $1.order }.map { $0.recipe }, id: \.self) { recipe in
                    Text(recipe.name)
                }
            }
            Section("Dinner") {
                ForEach(diary.objects.filter { $0.type == .dinner }.sorted { $0.order < $1.order }.map { $0.recipe }, id: \.self) { recipe in
                    Text(recipe.name)
                }
            }
            Section("Note") {
                Text(diary.note)
            }
            Section("Created At") {
                Text(diary.createdTimestamp.formatted(.dateTime.year().month().day()))
            }
            Section("Updated At") {
                Text(diary.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        DiaryView(selection: .constant(nil))
            .environment(preview.diaries[0])
    }
}
