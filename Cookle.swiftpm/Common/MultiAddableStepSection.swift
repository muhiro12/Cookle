//
//  MultiAddableStepSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/03.
//

import SwiftUI

struct MultiAddableStepSection: View {
    @Binding private var data: [String]

    init(data: Binding<[String]>) {
        self._data = data
    }

    var body: some View {
        Section {
            ForEach(data.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    Text((index + 1).description + ".")
                        .frame(width: 24)
                    TextField(
                        "Step",
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
        } header: {
            HStack {
                Text("Steps")
                Spacer()
                AddMultipleStepsButton(steps: $data)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        Form { () -> MultiAddableStepSection in
            MultiAddableStepSection(
                data: .constant(preview.recipes[0].steps + [""])
            )
        }
    }
}
