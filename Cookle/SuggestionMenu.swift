//
//  SuggestionMenu.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/16.
//

import SwiftUI
import SwiftData

struct SuggestionMenu<T: Tag>: View {
    @Binding var input: String

    @Query private var tags: [T]

    var body: some View {
        if tags.contains(where: { $0.value.lowercased().contains(input.lowercased()) }) {
            Menu {
                ForEach(tags.filter { $0.value.lowercased().contains(input.lowercased()) }) { tag in
                    Button(tag.value) {
                        input = tag.value
                    }
                }
            } label: {
                Image(systemName: "questionmark.circle")
            }
        }
    }
}

#Preview {
    SuggestionMenu<Category>(input: .constant("A"))
        .modelContainer(PreviewData.modelContainer)
}
