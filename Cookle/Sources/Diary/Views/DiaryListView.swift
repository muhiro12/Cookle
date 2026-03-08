//
//  DiaryListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/12.
//

import SwiftData
import SwiftUI
import TipKit

struct DiaryListView: View {
    private enum Layout {
        static let emptyStateSpacing = CGFloat(Int("16") ?? .zero)
    }

    @Environment(\.isPresented)
    private var isPresented

    @AppStorage(.isSubscribeOn)
    private var isSubscribeOn

    @Query(.diaries(.all))
    private var diaries: [Diary]
    @Query(.recipes(.all))
    private var recipes: [Recipe]

    @Binding private var diary: Diary?

    private let addDiaryTip = AddDiaryTip()
    private let startWithRecipesTip = StartWithRecipesTip()

    var body: some View {
        Group {
            if diaries.isNotEmpty {
                diaryList
            } else {
                emptyStateView
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

    var groupedDiaries: [(key: String, value: [Diary])] {
        Array(
            Dictionary(grouping: diaries) { diary in
                diary.date.formatted(.dateTime.year().month())
            }
            .sorted { lhs, rhs in
                lhs.value[0].date > rhs.value[0].date
            }
        )
    }

    var diaryList: some View {
        List(groupedDiaries, id: \.key, selection: $diary) { section in
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
    }

    var emptyStateView: some View {
        VStack(spacing: Layout.emptyStateSpacing) {
            if recipes.isEmpty {
                TipView(startWithRecipesTip)
            } else {
                TipView(addDiaryTip)
            }
            AddDiaryButton()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    init(selection: Binding<Diary?> = .constant(nil)) {
        _diary = selection
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        DiaryListView()
    }
}
