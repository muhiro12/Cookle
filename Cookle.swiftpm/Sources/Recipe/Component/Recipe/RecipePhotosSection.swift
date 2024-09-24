//
//  RecipePhotosSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipePhotosSection: View {
    @Environment(Recipe.self) private var recipe

    @State private var isPhotoDetailPresented = false

    var body: some View {
        if let objects = recipe.photoObjects,
           objects.isNotEmpty {
            Section {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(objects.sorted { $0.order < $1.order }, id: \.self) { photoObject in
                            if let photo = photoObject.photo,
                               let image = UIImage(data: photo.data) {
                                Button {
                                    isPhotoDetailPresented = true
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
            } header: {
                Text("Photos")
            }
            .fullScreenCover(isPresented: $isPhotoDetailPresented) {
                PhotoDetailNavigationView(photos: objects.compactMap(\.photo))
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
