//
//  MultiAddableSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftData
import SwiftUI

struct MultiAddableCategorySection: View {
    @Binding private var data: [String]

    init(data: Binding<[String]>) {
        self._data = data
    }

    var body: some View {
        Section {
            ForEach(data.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    TextField(
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
                    ) {
                        Text("Category")
                    }
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
        } header: {
            Text("Categories")
        }
    }
}

#Preview {
    CooklePreview { preview in
        Form { () -> MultiAddableCategorySection in
            MultiAddableCategorySection(
                data: .constant(preview.recipes[0].categories!.map { $0.value } + [""])
            )
        }
    }
}
