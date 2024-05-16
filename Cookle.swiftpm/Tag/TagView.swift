//
//  TagView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI

struct TagView<T: Tag>: View {
    @Environment(T.self) private var tag

    var body: some View {
        List {
            Section("Value") {
                Text(tag.value)
            }
            Section("Recipes") {
                ForEach(tag.recipes) {
                    Text($0.name)
                }
            }
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        TagView<Ingredient>()
            .environment(preview.ingredients[0])
    }
}
