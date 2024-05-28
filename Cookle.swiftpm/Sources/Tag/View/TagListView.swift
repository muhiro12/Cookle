//
//  TagListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftUI
import SwiftData

struct TagListView<T: Tag>: View {
    @Query(T.descriptor) private var tags: [T]

    @Binding private var selection: T?

    init(selection: Binding<T?>) {
        self._selection = selection
    }

    var body: some View {
        List(
            tags,
            id: \.self,
            selection: .init(
                get: {
                    selection
                },
                set: { value in
                    guard let value else {
                        return
                    }
                    selection = value
                }
            )
        ) { tag in
            Text(tag.value)
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        TagListView<Category>(selection: .constant(nil))
    }
}
