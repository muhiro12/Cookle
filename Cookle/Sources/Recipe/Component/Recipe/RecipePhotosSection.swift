//
//  RecipePhotosSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipePhotosSection: View {
    @Environment(Recipe.self) private var recipe

    @State private var selectedPhoto: Photo?

    var body: some View {
        if let objects = recipe.photoObjects,
           objects.isNotEmpty {
            Section {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(objects.sorted()) { photoObject in
                            if let photo = photoObject.photo,
                               let image = UIImage(data: photo.data) {
                                Button {
                                    selectedPhoto = photo
                                } label: {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 240)
                                        .clipShape(.rect(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .listRowInsets(.init(.zero))
                .listRowBackground(EmptyView())
            }
            .fullScreenCover(item: $selectedPhoto) { photo in
                PhotoDetailNavigationView(
                    photos: objects.sorted().compactMap(\.photo),
                    initialValue: photo
                )
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipePhotosSection()
                .environment(preview.recipes[0])
        }
    }
}
