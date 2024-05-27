//
//  DiaryListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/12.
//

import SwiftUI

struct DiaryListView: View {
    @Binding private var selection: Diary?

    private let diaries: [Diary]

    init(_ diaries: [Diary], selection: Binding<Diary?>) {
        self.diaries = diaries
        self._selection = selection
    }

    var body: some View {
        List(
            Array(
                Dictionary(
                    grouping: diaries,
                    by: { $0.date.formatted(.dateTime.year().month()) }
                )
                .sorted {
                    $0.key > $1.key
                }
            ),
            id: \.key,
            selection: $selection
        ) { section in
            Section(section.key) {
                ForEach(section.value, id: \.self) { diary in
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
