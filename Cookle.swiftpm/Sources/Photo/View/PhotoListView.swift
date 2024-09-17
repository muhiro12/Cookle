//
//  PhotoListView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import SwiftData
import SwiftUI

struct PhotoListView: View {
    @Query(.photos()) private var photos: [Photo]

    @Binding private var photo: Photo?

    init(selection: Binding<Photo?> = .constant(nil)) {
        _photo = selection
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 120))]) {
                ForEach(photos) { photo in
                    if photo.recipes.orEmpty.isNotEmpty,
                       let image = UIImage(data: photo.data) {
                        NavigationLink(value: photo) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("Photos"))
        .toolbar {
            ToolbarItem {
                AddRecipeButton()
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            PhotoListView()
        }
    }
}
