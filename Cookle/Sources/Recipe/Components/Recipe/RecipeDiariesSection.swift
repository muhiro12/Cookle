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

    var body: some View {
        if let diaries = recipe.diaries,
           diaries.isNotEmpty {
            Section {
                ForEach(diaries.sorted { lhs, rhs in
                    lhs.date > rhs.date
                }) { diary in
                    Text(diary.date.formatted(.dateTime.year().month().day()))
                }
            } header: {
                Text("Diaries")
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeDiariesSection()
            .environment(recipes[0])
    }
}
