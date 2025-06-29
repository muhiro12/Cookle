//
//  RecipeDiariesSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeDiariesSection: View {
    @Environment(RecipeEntity.self) private var recipe
    @Environment(\.modelContext) private var context

    var body: some View {
        if let diaries = try? recipe.model(context: context)?.diaries,
           diaries.isNotEmpty {
            Section {
                ForEach(diaries.sorted {
                    $0.date > $1.date
                }) {
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
                .environment(RecipeEntity(preview.recipes[0])!)
        }
    }
}
