//
//  PhotoView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import SwiftData
import SwiftUI

struct PhotoView: View {
    @Environment(Photo.self) private var photo

    @Binding private var recipe: Recipe?

    @State private var isPhotoDetailPresented = false

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }

    var body: some View {
        List(selection: $recipe) {
            Section {
                if let image = UIImage(data: photo.data) {
                    Button {
                        isPhotoDetailPresented = true
                    } label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(EmptyView())
                }
            }
            Section {
                ForEach(photo.recipes.orEmpty) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeLabel()
                            .labelStyle(.titleOnly)
                            .environment(recipe)
                    }
                }
            } header: {
                Text("Recipe")
            }
            Section {
                Text(photo.createdTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Created At")
            }
            Section {
                Text(photo.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Updated At")
            }
        }
        .navigationTitle(photo.title)
        .fullScreenCover(isPresented: $isPhotoDetailPresented) {
            PhotoDetailNavigationView(photos: [photo])
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photos: [Photo]
    PhotoView()
        .environment(photos[0])
}
