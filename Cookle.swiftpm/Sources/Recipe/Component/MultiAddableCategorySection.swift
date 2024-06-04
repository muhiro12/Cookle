//
//  MultiAddableSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI
import SwiftData

struct MultiAddableCategorySection: View {
    @Binding private var data: [String]

    init(data: Binding<[String]>) {
        self._data = data
    }

    var body: some View {
        Section("Categories") {
            ForEach(data.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    TextField(
                        "Category",
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
                    SuggestionMenu<Category>(input: $data[index])
                        .frame(width: 24)
                }
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
    CooklePreview { preview in
        Form { () -> MultiAddableCategorySection in
            MultiAddableCategorySection(
                data: .constant(preview.recipes[0].categories.map { $0.value } + [""])
            )
        }
    }
}
