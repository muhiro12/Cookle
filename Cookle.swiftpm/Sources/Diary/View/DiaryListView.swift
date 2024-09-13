//
//  DiaryListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/12.
//

import SwiftData
import SwiftUI

struct DiaryListView: View {
    @Query(.diaries()) private var diaries: [Diary]

    @Binding private var selection: CookleSelectionValue?

    init(selection: Binding<CookleSelectionValue?> = .constant(nil)) {
        _selection = selection
    }

    var body: some View {
        List(
            Array(
                Dictionary(
                    grouping: diaries
                ) { $0.date.formatted(.dateTime.year().month()) }
                .sorted {
                    $0.value[0].date > $1.value[0].date
                }
            ),
            id: \.key,
            selection: $selection
        ) { section in
            Section(section.key) {
                ForEach(section.value, id: \.self) { diary in
                    if diary.recipes.orEmpty.isNotEmpty {
                        NavigationLink(selection: .diary(diary)) {
                            Text(diary.date.formatted(.dateTime.month().day()))
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("Diaries"))
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
            DiaryListView()
        }
    }
}
