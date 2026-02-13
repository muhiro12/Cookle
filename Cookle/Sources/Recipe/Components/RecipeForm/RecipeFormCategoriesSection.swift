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

    init(_ categories: Binding<[String]>) {
        self._categories = categories
    }

    var body: some View {
        Section {
            ForEach(categories.indices, id: \.self) { index in
                TextField(text: $categories[index], axis: .vertical) {
                    Text("Italian")
                }
                .focused($focusedIndex, equals: index)
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        SuggestionButtons<Category>(input: $categories[index])
                            .hidden(focusedIndex != index)
                    }
                }
            }
            .onDelete {
                categories.remove(atOffsets: $0)
            }
        } header: {
            Text("Categories")
        }
        .onChange(of: categories) {
            categories.removeAll {
                $0.isEmpty
            }
            categories.append(.empty)
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var categories: [Category]
    Form { () -> RecipeFormCategoriesSection in
        RecipeFormCategoriesSection(
            .constant(categories.map(\.value) + [.empty])
        )
    }
}
