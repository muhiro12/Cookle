//
//  RecipeFormCategoriesSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI

struct RecipeFormCategoriesSection: View {
    @Binding private var categories: [String]

    init(_ categories: Binding<[String]>) {
        self._categories = categories
    }

    var body: some View {
        Section {
            ForEach(categories.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    TextField(
                        text: .init(
                            get: {
                                guard index < categories.endIndex else {
                                    return ""
                                }
                                return categories[index]
                            },
                            set: { value in
                                guard index < categories.endIndex else {
                                    return
                                }
                                categories[index] = value
                                guard !value.isEmpty,
                                      !categories.contains("") else {
                                    return
                                }
                                categories.append("")
                            }
                        ),
                        axis: .vertical
                    ) {
                        Text("Category")
                    }
                    SuggestionMenu<Category>(input: $categories[index])
                        .frame(width: 24)
                }
            }
        } header: {
            Text("Categories")
        }
    }
}

#Preview {
    CooklePreview { preview in
        Form { () -> RecipeFormCategoriesSection in
            RecipeFormCategoriesSection(
                .constant(preview.recipes[0].categories!.map { $0.value } + [""])
            )
        }
    }
}
