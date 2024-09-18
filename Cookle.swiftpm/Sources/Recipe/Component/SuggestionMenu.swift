//
//  SuggestionMenu.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/16.
//

import SwiftData
import SwiftUI

struct SuggestionMenu<T: Tag>: View {
    @Binding private var input: String

    @Query(T.descriptor) private var tags: [T]

    init(input: Binding<String>) {
        self._input = input
    }

    var body: some View {
        HStack {
            if tags.contains(where: { $0.value.normalizedContains(input) }) {
                Menu {
                    ForEach(tags.filter { $0.value.normalizedContains(input) }) { tag in
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
}

#Preview {
    CooklePreview { _ in
        SuggestionMenu<Category>(input: .constant("A"))
    }
}
