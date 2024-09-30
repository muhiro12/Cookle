//
//  SuggestionButtons.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/16.
//

import SwiftData
import SwiftUI

struct SuggestionButtons<T: Tag>: View {
    @Query private var suggestions: [T]

    @Binding private var input: String

    init(input: Binding<String>) {
        _input = input
        _suggestions = .init(T.descriptor(.valueContains(input.wrappedValue)))
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(suggestions) { suggestion in
                    Button(suggestion.value) {
                        input = suggestion.value
                    }
                    Divider()
                }
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        SuggestionButtons<Category>(input: .constant("A"))
    }
}
