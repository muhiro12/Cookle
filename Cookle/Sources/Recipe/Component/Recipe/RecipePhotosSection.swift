//
//  RecipePhotosSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipePhotosSection: View {
    @Environment(RecipeEntity.self) private var recipe
    @Environment(\.modelContext) private var context

    @State private var selectedPhoto: Photo?

    var body: some View {
        if let photoObjects = try? recipe.model(context: context)?.photoObjects,
           photoObjects.isNotEmpty {
            Section {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(photoObjects.sorted()) { photoObject in
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
                    photos: photoObjects.sorted().compactMap(\.photo),
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
                .environment(RecipeEntity(preview.recipes[0])!)
        }
    }
}
