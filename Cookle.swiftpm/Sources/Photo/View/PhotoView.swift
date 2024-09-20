//
//  PhotoView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

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
                    HStack {
                        Spacer()
                        Button {
                            isPhotoDetailPresented = true
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 240)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .listRowBackground(EmptyView())
                }
            }
            Section {
                ForEach(photo.recipes.orEmpty, id: \.self) { recipe in
                    NavigationLink(value: recipe) {
                        Text(recipe.name)
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

#Preview {
    CooklePreview { preview in
        PhotoView()
            .environment(preview.photos[0])
    }
}
