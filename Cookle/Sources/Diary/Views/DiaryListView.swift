//
//  DiaryListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/12.
//

import SwiftData
import SwiftUI

struct DiaryListView: View {
    @Environment(\.isPresented)
    private var isPresented

    @AppStorage(.isSubscribeOn)
    private var isSubscribeOn

    @Query(.diaries(.all))
    private var diaries: [Diary]

    @Binding private var diary: Diary?

    var body: some View {
        Group {
            if diaries.isNotEmpty {
                List(
                    Array(
                        Dictionary(
                            grouping: diaries
                        ) { diary in
                            diary.date.formatted(.dateTime.year().month())
                        }
                        .sorted { lhs, rhs in
                            lhs.value[0].date > rhs.value[0].date
                        }
                    ),
                    id: \.key,
                    selection: $diary
                ) { section in
                    Section(section.key) {
                        ForEach(section.value) { diary in
                            NavigationLink(value: diary) {
                                DiaryLabel()
                                    .environment(diary)
                            }
                            .hidden(diary.recipes.orEmpty.isEmpty)
                        }
                    }
                    AdvertisementSection(.small)
                        .hidden(isSubscribeOn)
                }
            } else {
                AddDiaryButton()
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

    init(selection: Binding<Diary?> = .constant(nil)) {
        _diary = selection
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        DiaryListView()
    }
}
