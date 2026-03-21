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
    @Environment(\.isPresented)
    private var isPresented
    @Environment(MainNavigationModel.self)
    private var navigationModel

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
        .cookleTopLevelNavigationChrome("Diaries")
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
        List(groupedDiaries, id: \.key) { section in
            Section(section.key) {
                ForEach(section.value) { diary in
                    Button {
                        self.diary = diary
                    } label: {
                        DiaryLabel()
                            .environment(diary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .hidden(diary.recipes.orEmpty.isEmpty)
                }
            }
            AdvertisementSection(.small)
                .hidden(isSubscribeOn)
        }
    }

    var emptyStateView: some View {
        ContentUnavailableView {
            Label(
                recipes.isEmpty ? "No Diaries Yet" : "Ready To Add A Diary",
                systemImage: recipes.isEmpty ? "book.closed" : "fork.knife"
            )
        } description: {
            Text(
                recipes.isEmpty
                    ? "Add a recipe before creating your first diary entry."
                    : "Create a diary entry to record what you cooked."
            )
        } actions: {
            if recipes.isEmpty {
                Button {
                    navigationModel.selectedTab = .recipe
                } label: {
                    Text("Open Recipes")
                }
                .popoverTip(
                    startWithRecipesTip,
                    arrowEdge: .top
                )
            } else {
                AddDiaryButton()
                    .popoverTip(
                        addDiaryTip,
                        arrowEdge: .top
                    )
            }
        }
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
