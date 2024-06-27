//
//  TagListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftData
import SwiftUI

struct TagListView<T: Tag>: View {
    @Query(T.descriptor) private var tags: [T]

    @Binding private var selection: T?

    init(selection: Binding<T?>) {
        self._selection = selection
    }

    var body: some View {
        List(tags, id: \.self, selection: $selection) { tag in
            Text(tag.value)
        }
    }
}

#Preview {
    CooklePreview { _ in
        TagListView<Category>(selection: .constant(nil))
    }
}
