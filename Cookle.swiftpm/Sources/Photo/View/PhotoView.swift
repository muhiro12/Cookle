//
//  PhotoView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import SwiftUI

struct PhotoView: View {
    @Environment(Photo.self) private var photo

    @Binding private var selection: Recipe?

    @State private var isPhotoDetailPresented = false

    init(selection: Binding<Recipe?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                if let image = UIImage(data: photo.data) {
                    Button {
                        isPhotoDetailPresented = true
                    } label: {
                        Image(uiImage: image)
                            .resizable()
                            .frame(height: 240)
                    }
                }
            }
            Section("Recipe") {
                ForEach(photo.recipes.orEmpty, id: \.self) { recipe in
                    Text(recipe.name)
                }
            }
            Section("Created At") {
                Text(photo.createdTimestamp.formatted(.dateTime.year().month().day()))
            }
            Section("Updated At") {
                Text(photo.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            }
        }
        .navigationTitle(photo.title)
        .fullScreenCover(isPresented: $isPhotoDetailPresented) {
            PhotoDetailView(photos: [photo])
        }
    }
}

#Preview {
    CooklePreview { preview in
        PhotoView(selection: .constant(nil))
            .environment(preview.photos[0])
    }
}
