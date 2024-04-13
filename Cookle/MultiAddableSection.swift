//
//  MultiAddableSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI

struct MultiAddableSection: View {
    @Binding var data: [String]

    let title: String
    let tagList: [Tag]
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
                    if tagList.contains(where: { $0.value.lowercased().contains(data[index].lowercased()) }) {
                        Menu {
                            ForEach(tagList.filter { $0.value.lowercased().contains(data[index].lowercased()) }) { tag in
                                Button(tag.value) {
                                    data[index] = tag.value
                                }
                            }
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
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
    Form {
        MultiAddableSection(
            data: .constant(Array(PreviewData.instructionsList.prefix(5)) + [""]),
            title: "Instructions",
            tagList: PreviewData.tagStore.instructionTagList,
            shouldShowNumber: true
        )
    }
}
