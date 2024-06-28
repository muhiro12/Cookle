//
//  DiaryListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/12.
//

import SwiftData
import SwiftUI

struct DiaryListView: View {
    @Query(Diary.descriptor) private var diaries: [Diary]

    @Binding private var selection: Diary?

    init(selection: Binding<Diary?>) {
        self._selection = selection
    }

    var body: some View {
        List(
            Array(
                Dictionary(
                    grouping: diaries
                ) { $0.date.formatted(.dateTime.year().month()) }
                .sorted {
                    $0.key > $1.key
                }
            ),
            id: \.key,
            selection: $selection
        ) { section in
            Section(section.key) {
                ForEach(section.value, id: \.self) { diary in
                    if diary.recipes.orEmpty.isNotEmpty {
                        Text(diary.date.formatted(.dateTime.month().day()))
                    }
                }
            }
        }
        .navigationTitle("Diaries")
        .toolbar {
            ToolbarItem {
                AddDiaryButton()
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            DiaryListView(selection: .constant(nil))
        }
    }
}
