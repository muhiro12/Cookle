//
//  RecipeGridView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/12.
//

import SwiftUI

struct RecipeGridView: View {
    @Binding private var selection: Recipe?

    private let recipes: [Recipe]

    init(_ recipes: [Recipe], selection: Binding<Recipe?>) {
        self.recipes = recipes
        self._selection = selection
    }

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                LazyHGrid(rows: (0..<3).map { _ in .init() }) {
                    ForEach(recipes) { recipe in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundColor(.white)
                                .shadow(radius: 1)
                            VStack {
                                Text(recipe.name)
                                    .font(.title)
                                    .bold()
                                Divider()
                                Text(recipe.ingredientList.joined(separator: ", "))
                                Spacer()
                            }
                            .padding()
                        }
                        .frame(width: 320)
                        .onTapGesture {
                            selection = recipe
                        }
                    }
                }
                .padding()
            }
            Spacer()
        }
    }
}

#Preview {
    RecipeGridView((0..<10).map { _ in PreviewData.randomRecipe()},
                   selection: .constant(nil))
}
