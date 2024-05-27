//
//  TagView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI

struct TagView<T: Tag>: View {
    @Environment(T.self) private var tag

    @Binding private var selection: Recipe?

    init(selection: Binding<Recipe?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Section("Value") {
                Text(tag.value)
            }
            Section("Recipes") {
                ForEach(tag.recipes, id: \.self) {
                    Text($0.name)
                }
            }
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        TagView<Ingredient>(selection: .constant(nil))
            .environment(preview.ingredients[0])
    }
}
