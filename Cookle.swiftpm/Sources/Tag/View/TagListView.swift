//
//  TagListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftUI

struct TagListView<T: Tag>: View {
    @Binding private var selection: T?

    private let tags: [T]

    init(_ tags: [T], selection: Binding<T?>) {
        self.tags = tags
        self._selection = selection
    }

    var body: some View {
        List(tags, id: \.self, selection: $selection) { tag in
            Text(tag.value)
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        TagListView(preview.categories, selection: .constant(nil))
    }
}
