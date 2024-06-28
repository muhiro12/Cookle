//
//  PhotoListView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import SwiftData
import SwiftUI

struct PhotoListView: View {
    @Query(Photo.descriptor) private var photos: [Photo]

    @Binding private var selection: Photo?

    init(selection: Binding<Photo?>) {
        self._selection = selection
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 120))]) {
                ForEach(photos) { photo in
                    if photo.recipes.orEmpty.isNotEmpty,
                       let image = UIImage(data: photo.data) {
                        Button {
                            selection = photo
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
            }
        }
        .navigationTitle("Photos")
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            PhotoListView(selection: .constant(nil))
        }
    }
}
