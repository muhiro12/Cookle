//
//  RecipeDiariesSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import MHUI
import SwiftData
import SwiftUI

struct RecipeDiariesSection: View {
    private static let previewLimit = 3

    @Environment(Recipe.self)
    private var recipe

    var presentation: RecipeSectionPresentation = .native

    var body: some View {
        let diaries = Set(recipe.diaries ?? []).sorted { lhs, rhs in
            lhs.date > rhs.date
        }
        if !diaries.isEmpty {
            RecipeContentSection("Diaries (\(diaries.count))", presentation: presentation) {
                ForEach(diaries.prefix(Self.previewLimit)) { diary in
                    RecipeDiaryRow(diary: diary)
                }
                if diaries.count > Self.previewLimit {
                    NavigationLink {
                        RecipeDiaryHistoryView()
                            .environment(recipe)
                    } label: {
                        Text("See All")
                            .cookleButtonRowContent()
                    }
                }
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    NavigationStack {
        VStack {
            RecipeDiariesSection(presentation: .mhui)
                .environment(recipes[0])
        }
        .mhScreen()
    }
}
