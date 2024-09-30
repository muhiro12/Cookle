//
//  DiaryListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/12.
//

import SwiftData
import SwiftUI
import SwiftUtilities

struct DiaryListView: View {
    @Environment(\.isPresented) private var isPresented

    @Query(.diaries(.all)) private var diaries: [Diary]

    @Binding private var diary: Diary?

    init(selection: Binding<Diary?> = .constant(nil)) {
        _diary = selection
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
            selection: $diary
        ) { section in
            Section(section.key) {
                ForEach(section.value) { diary in
                    NavigationLink(value: diary) {
                        HStack {
                            VStack {
                                Text(diary.date.formatted(.dateTime.weekday()))
                                    .font(.callout.uppercaseSmallCaps())
                                Text(diary.date.formatted(.dateTime.day(.twoDigits)))
                                    .font(.title.monospacedDigit())
                            }
                            Divider()
                            Text(diary.recipes.orEmpty.map { $0.name }.joined(separator: ", "))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .hidden(diary.recipes.orEmpty.isEmpty)
                }
            }
        }
        .navigationTitle(Text("Diaries"))
        .toolbar {
            ToolbarItem {
                AddDiaryButton()
            }
            ToolbarItem {
                CloseButton()
                    .hidden(!isPresented)
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
