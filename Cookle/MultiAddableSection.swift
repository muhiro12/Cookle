//
//  MultiAddableSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI
import SwiftData

struct MultiAddableSection<T>: View {
    @Binding var data: [String]

    let title: String
    let shouldShowNumber: Bool

    var body: some View {
        Section(title) {
            ForEach(data.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    if shouldShowNumber {
                        Text((index + 1).description + ".")
                    }
                    TextField(
                        title,
                        text: .init(
                            get: {
                                guard index < data.endIndex else {
                                    return ""
                                }
                                return data[index]
                            },
                            set: { value in
                                guard index < data.endIndex else {
                                    return
                                }
                                data[index] = value
                                guard !value.isEmpty,
                                      !data.contains("") else {
                                    return
                                }
                                data.append("")
                            }
                        ),
                        axis: .vertical
                    )
                    switch T.self {
                    case is Ingredient.Type:
                        SuggestionMenu<Ingredient>(input: $data[index])
                    case is Category.Type:
                        SuggestionMenu<Category>(input: $data[index])
                    default:
                        EmptyView()
                    }
                }
            }
            .onMove {
                data.move(fromOffsets: $0, toOffset: $1)
            }
            .onDelete {
                data.remove(atOffsets: $0)
                guard data.isEmpty else {
                    return
                }
                data.append("")
            }
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        Form { () -> MultiAddableSection<Ingredient> in
            MultiAddableSection<Ingredient>(
                data: .constant(preview.ingredients.prefix(5).map { $0.value } + [""]),
                title: "Ingredient",
                shouldShowNumber: true
            )
        }
    }
}
