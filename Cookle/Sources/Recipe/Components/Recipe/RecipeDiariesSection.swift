//
//  RecipeDiariesSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeDiariesSection: View {
    @Environment(Recipe.self)
    private var recipe
    @Environment(\.openCookleRoute)
    private var openCookleRoute

    var body: some View {
        if let diaries = recipe.diaries,
           diaries.isNotEmpty {
            Section {
                ForEach(diaries.sorted { lhs, rhs in
                    lhs.date > rhs.date
                }) { diary in
                    Button {
                        openDiary(diary)
                    } label: {
                        Text(diary.date.formatted(.dateTime.year().month().day()))
                            .cookleButtonRowContent()
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Diaries")
            }
        }
    }
}

private extension RecipeDiariesSection {
    func openDiary(_ diary: Diary) {
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: diary.date
        )
        guard let year = dateComponents.year,
              let month = dateComponents.month,
              let day = dateComponents.day else {
            openCookleRoute(.diary)
            return
        }
        openCookleRoute(
            .diaryDate(
                year: year,
                month: month,
                day: day
            )
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeDiariesSection()
            .environment(recipes[0])
    }
}
