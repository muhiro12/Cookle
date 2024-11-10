//
//  RecipeFormPhotosSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import PhotosUI
import SwiftUI

struct RecipeFormPhotosSection: View {
    @Environment(Recipe.self) private var recipe: Recipe?
    @Environment(\.editMode) private var editMode

    @Binding private var photos: [Data]

    @State private var photosPickerItems = [PhotosPickerItem]()

    init(_ photos: Binding<[Data]>) {
        _photos = photos
    }

    var body: some View {
        Section {
            if editMode?.wrappedValue == .inactive {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(photos, id: \.self) { photo in
                            if let image = UIImage(data: photo) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                            }
                        }
                        PhotosPicker(
                            selection: $photosPickerItems,
                            selectionBehavior: .ordered,
                            matching: .images
                        ) {
                            Image(systemName: "photo.badge.plus")
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
            } else {
                ForEach(photos, id: \.self) { photo in
                    if let image = UIImage(data: photo) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                    }
                }
                .onMove {
                    photos.move(fromOffsets: $0, toOffset: $1)
                }
                .onDelete {
                    photos.remove(atOffsets: $0)
                }
            }
        } header: {
            Text("Photos")
        }
        .onChange(of: photosPickerItems) {
            photos = (recipe?.photos).orEmpty.map(\.data)
            Task {
                for item in photosPickerItems {
                    guard let data = try? await item.loadTransferable(type: Data.self) else {
                        continue
                    }

                    var photo = data
                    var compressionQuality = 1.0
                    let maxSize = 500 * 1_024

                    while photo.count > maxSize && compressionQuality > 0 {
                        if let jpeg = UIImage(data: data)?.jpegData(compressionQuality: compressionQuality) {
                            photo = jpeg
                        }
                        compressionQuality -= 0.1
                    }

                    photos.append(photo.count < data.count ? photo : data)
                }
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        Form {
            RecipeFormPhotosSection(.constant(preview.photos.map(\.data)))
        }
    }
}
