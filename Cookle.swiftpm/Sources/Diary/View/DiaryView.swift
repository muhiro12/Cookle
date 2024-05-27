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
            ForEach(diary.objects) { object in
                Section(object.type.title) {
                    ForEach(object.recipes, id: \.self) { recipe in
                        Text(recipe.name)
                    }
                }
            }
            Section("Note") {
                Text(diary.note)
            }
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        DiaryView(selection: .constant(nil))
            .environment(preview.diaries[0])
    }
}
