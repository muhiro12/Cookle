//
//  DIaryListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/12.
//

import SwiftUI

struct DiaryListView: View {
    @Binding private var selection: Diary.ID?

    private let diaries: [Diary]

    init(_ diaries: [Diary], selection: Binding<Diary.ID?>) {
        self.diaries = diaries
        self._selection = selection
    }

    var body: some View {
        List(
            Array(
                Dictionary(
                    grouping: diaries,
                    by: { $0.date.formatted(.iso8601.year().month()) }
                )
                .sorted {
                    $0.key > $1.key
                }
            ),
            id: \.key,
            selection: $selection
        ) { section in
            Section(section.key) {
                ForEach(section.value) { diary in
                    Text(diary.date.formatted(.dateTime.month().day()))
                }
            }
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        DiaryListView(preview.diaries, selection: .constant(nil))
    }
}
