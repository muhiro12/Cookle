//
//  RecipeFormCategoriesSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftData
import SwiftUI

struct RecipeFormCategoriesSection: View {
    @Binding private var categories: [String]

    @FocusState private var focusedIndex: Int?

    var body: some View {
        Section {
            ForEach(categories.indices, id: \.self) { index in
                TextField(text: $categories[index], axis: .vertical) {
                    Text("Italian")
                }
                .focused($focusedIndex, equals: index)
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        if focusedIndex == index {
                            SuggestionButtons<Category>(input: $categories[index])
                        }
                    }
                }
            }
            .onDelete { offsets in
                categories.remove(atOffsets: offsets)
            }
        } header: {
            Text("Categories")
        }
        .onChange(of: categories) {
            categories = RecipeFormPlaceholderRows.normalizedStrings(
                categories
            )
        }
    }

    init(_ categories: Binding<[String]>) {
        self._categories = categories
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var categories: [Category]
    Form { () -> RecipeFormCategoriesSection in
        RecipeFormCategoriesSection(
            .constant(categories.map(\.value) + [""])
        )
    }
}
