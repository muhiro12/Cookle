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
    let shouldShowNumber: Bool

    var body: some View {
        Section {
            Text(title)
                .font(.headline)
            ForEach(data.indices, id: \.self) { index in
                HStack {
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
                        )
                    )
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
            shouldShowNumber: true
        )
    }
}
