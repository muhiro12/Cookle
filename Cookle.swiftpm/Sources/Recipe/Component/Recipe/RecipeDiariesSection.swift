//
//  RecipeDiariesSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeDiariesSection: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        if let diaries = recipe.diaries,
           diaries.isNotEmpty {
            Section {
                ForEach(diaries) {
                    Text($0.date.formatted(.dateTime.year().month().day()))
                }
            } header: {
                Text("Diaries")
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipeDiariesSection()
                .environment(preview.recipes[0])
        }
    }
}
