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

    var body: some View {
        ScrollView(.horizontal) {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(
                    spacing: SuggestionButtonsLayout.buttonSpacing
                ) {
                    suggestionButtonRow
                }
            } else {
                suggestionButtonRow
            }
        }
        .scrollIndicators(.hidden)
    }

    init(input: Binding<String>) {
        _input = input
        _suggestions = .init(T.descriptor(.valueContains(input.wrappedValue)))
    }
}

private extension SuggestionButtons {
    var suggestionButtonRow: some View {
        HStack(spacing: SuggestionButtonsLayout.buttonSpacing) {
            ForEach(suggestions) { suggestion in
                Button(suggestion.value) {
                    input = suggestion.value
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .padding(
                    .horizontal,
                    SuggestionButtonsLayout.buttonHorizontalPadding
                )
                .padding(
                    .vertical,
                    SuggestionButtonsLayout.buttonVerticalPadding
                )
                .cookleGlassControl(
                    in: Capsule(style: .continuous)
                )
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    SuggestionButtons<Category>(input: .constant("A"))
}
