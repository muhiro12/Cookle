//
//  RecipePhotosSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipePhotosSection: View {
    private enum Layout {
        static let photoHeight = CGFloat(Int("240") ?? .zero)
        static let photoCornerRadius = CGFloat(Int("8") ?? .zero)
    }

    @Environment(Recipe.self)
    private var recipe

    @State private var selectedPhoto: Photo?

    var body: some View {
        let orderedPhotoObjects = recipe.orderedPhotoObjects
        let orderedPhotos = recipe.orderedPhotos

        if orderedPhotos.isNotEmpty {
            Section {
                ScrollView(.horizontal) {
                    LazyHStack {
                        if orderedPhotoObjects.isNotEmpty {
                            ForEach(orderedPhotoObjects) { photoObject in
                                photoTile(for: photoObject)
                            }
                        } else {
                            ForEach(orderedPhotos) { photo in
                                photoTile(for: photo)
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
                    photos: orderedPhotos,
                    initialValue: photo
                )
            }
        }
    }
}

private extension RecipePhotosSection {
    @ViewBuilder
    func photoTile(for photoObject: PhotoObject) -> some View {
        if let photo = photoObject.photo {
            photoTile(for: photo)
        }
    }

    @ViewBuilder
    func photoTile(for photo: Photo) -> some View {
        if let image = UIImage(data: photo.data) {
            Button {
                selectedPhoto = photo
            } label: {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text("Open Photo"))
                    .frame(height: Layout.photoHeight)
                    .clipShape(.rect(cornerRadius: Layout.photoCornerRadius))
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipePhotosSection()
            .environment(recipes[0])
    }
}
