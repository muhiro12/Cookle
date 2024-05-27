//
//  DiaryListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/12.
//

import SwiftUI
import SwiftData

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
        DiaryListView(selection: .constant(nil))
    }
}
