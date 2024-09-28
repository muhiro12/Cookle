//
//  PhotoListView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import SwiftData
import SwiftUI
import SwiftUtilities

struct PhotoListView: View {
    @Environment(\.isPresented) private var isPresented

    @Query(.photos(.all)) private var photos: [Photo]

    @Binding private var photo: Photo?

    init(selection: Binding<Photo?> = .constant(nil)) {
        _photo = selection
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 120))]) {
                ForEach(photos) { photo in
                    if photo.recipes.isNotEmpty,
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
            ToolbarItem {
                CloseButton()
                    .hidden(!isPresented)
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
