//
//  PhotoListView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import SwiftData
import SwiftUI

struct PhotoListView: View {
    @Query(sort: \Photo.modifiedTimestamp, order: .reverse)
    private var photos: [Photo]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 120))]) {
                ForEach(photos) { photo in
                    if let image = UIImage(data: photo.data) {
                        NavigationLink(value: photo) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        PhotoListView()
    }
}
