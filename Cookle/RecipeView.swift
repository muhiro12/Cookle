//
//  RecipeView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct RecipeView: View {
    @Environment(Recipe.self) var recipe

    var body: some View {
        List {
            VStack(alignment: .leading) {
                Text("image")
                    .font(.headline)
                ForEach(recipe.imageList, id: \.self) {
                    if let image = UIImage(data: $0) {
                        Image(uiImage: image)
                    }
                }
            }
            VStack(alignment: .leading) {
                Text("ingredients")
                    .font(.headline)
                ForEach(recipe.ingredientList, id: \.self) {
                    Text($0)
                }
            }
            VStack(alignment: .leading) {
                Text("instructions")
                    .font(.headline)
                ForEach(Array(recipe.instructionList.enumerated()), id: \.offset) { values in
                    HStack(alignment: .top) {
                        Text(values.offset.description + ".")
                            .frame(width: 24)
                        Text(values.element)
                    }
                }
            }
            VStack(alignment: .leading) {
                Text("tags")
                    .font(.headline)
                ForEach(recipe.tagList, id: \.self) {
                    Text($0)
                }
            }
            VStack(alignment: .leading) {
                Text("updateDate")
                    .font(.headline)
                Text(recipe.updateDate.description)
            }
            VStack(alignment: .leading) {
                Text("creationDate")
                    .font(.headline)
                Text(recipe.creationDate.description)
            }
        }
    }
}

#Preview {
    RecipeView()
        .environment(PreviewData.randomRecipe())
}
