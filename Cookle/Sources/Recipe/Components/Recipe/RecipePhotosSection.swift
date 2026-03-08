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
        if let photoObjects = recipe.photoObjects,
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
                                        .accessibilityLabel(Text("Open Photo"))
                                        .frame(height: Layout.photoHeight)
                                        .clipShape(.rect(cornerRadius: Layout.photoCornerRadius))
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

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipePhotosSection()
            .environment(recipes[0])
    }
}
