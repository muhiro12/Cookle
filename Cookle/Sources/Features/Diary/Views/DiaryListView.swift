//
//  DiaryListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/12.
//

import MHPlatform
import SwiftData
import SwiftUI
import TipKit

struct DiaryListView: View {
    @Environment(\.isPresented)
    private var isPresented
    @Environment(\.modelContext)
    private var context
    @Environment(MainNavigationModel.self)
    private var navigationModel
    @Environment(CookleTipController.self)
    private var tipController

    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn

    @Query(.diaries(.all))
    private var diaries: [Diary]
    @Query(.recipes(.all))
    private var recipes: [Recipe]

    @Binding private var diary: Diary?
    @State private var isSuggestedDiaryPresented = false
    @State private var suggestedDiaryPrefill: DiaryFormPrefill?

    private let addDiaryTip = AddDiaryTip()
    private let startWithRecipesTip = StartWithRecipesTip()

    var body: some View {
        Group {
            if !diaries.isEmpty {
                diaryList
            } else {
                emptyStateView
            }
        }
        .cookleTopLevelNavigationChrome("Diaries")
        .sheet(isPresented: $isSuggestedDiaryPresented) {
            DiaryFormNavigationView(
                prefill: suggestedDiaryPrefill
            )
        }
        .toolbar {
            ToolbarItem {
                AddDiaryButton()
            }
            ToolbarItem {
                if isPresented {
                    CloseButton()
                }
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
        List {
            if let topSuggestion {
                Section {
                    DiaryTopSuggestionButton(
                        suggestion: topSuggestion
                    ) {
                        presentSuggestedDiary(
                            for: topSuggestion
                        )
                    }
                }
            }

            ForEach(groupedDiaries, id: \.key) { section in
                Section(section.key) {
                    ForEach(section.value) { diary in
                        Button {
                            $diary.cookleSelectForNavigation(
                                diary
                            )
                        } label: {
                            DiaryLabel()
                                .environment(diary)
                                .cookleButtonRowContent()
                        }
                        .buttonStyle(.plain)
                    }
                }
                if !isSubscribeOn {
                    AdvertisementSection(.small)
                }
            }
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
                .cooklePopoverTip(
                    startWithRecipesTip,
                    arrowEdge: .top
                )
            } else if let topSuggestion {
                Button {
                    presentSuggestedDiary(
                        for: topSuggestion
                    )
                } label: {
                    topSuggestion.actionTitle
                }
                AddDiaryButton()
            } else {
                AddDiaryButton()
                    .cooklePopoverTip(
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

private extension DiaryListView {
    var topSuggestion: DiaryTopSuggestion? {
        do {
            return try DiaryOperations.topSuggestion(
                context: context
            )
        } catch {
            return nil
        }
    }

    func presentSuggestedDiary(
        for renderedSuggestion: DiaryTopSuggestion
    ) {
        suggestedDiaryPrefill = suggestedPrefill(
            for: renderedSuggestion
        )
        tipController.donateDidOpenDiaryForm()
        isSuggestedDiaryPresented = true
    }

    func suggestedPrefill(
        for renderedSuggestion: DiaryTopSuggestion
    ) -> DiaryFormPrefill? {
        do {
            guard let freshSuggestion = try DiaryOperations.topSuggestion(
                context: context
            ) else {
                return nil
            }

            guard freshSuggestion == renderedSuggestion else {
                return nil
            }

            guard let recipe = try RecipeStableIdentifierCodec.recipe(
                from: renderedSuggestion.recipeStableIdentifier,
                context: context
            ) else {
                return nil
            }

            return .init(
                date: renderedSuggestion.date,
                breakfasts: renderedSuggestion.mealType == .breakfast ? [recipe] : [],
                lunches: renderedSuggestion.mealType == .lunch ? [recipe] : [],
                dinners: renderedSuggestion.mealType == .dinner ? [recipe] : [],
                note: ""
            )
        } catch {
            return nil
        }
    }
}
