//
//  RecipeFormPhotosSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import PhotosUI
import SwiftData
import SwiftUI

struct RecipeFormPhotosSection: View {
    @Environment(Recipe.self)
    private var recipe: Recipe?
    @Environment(\.editMode)
    private var editMode

    @Binding private var photos: [PhotoData]

    @State private var photosPickerItems = [PhotosPickerItem]()
    @State private var isPhotosPickerPresented = false
    @State private var isImagePlaygroundPresented = false

    var body: some View {
        Section {
            Group {
                if editMode?.wrappedValue == .inactive {
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(photos, id: \.data) { photo in
                                if let image = UIImage(data: photo.data) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 120)
                                }
                            }
                            if CookleImagePlayground.isSupported {
                                Menu {
                                    Button {
                                        isPhotosPickerPresented = true
                                    } label: {
                                        Label {
                                            Text("Choose Photo")
                                        } icon: {
                                            Image(systemName: "photo.on.rectangle")
                                        }
                                    }
                                    Button {
                                        isImagePlaygroundPresented = true
                                    } label: {
                                        Label {
                                            Text("Image Playground")
                                        } icon: {
                                            Image(systemName: "apple.image.playground")
                                        }
                                    }
                                } label: {
                                    Image(systemName: "photo.badge.plus")
                                }
                            } else {
                                Button {
                                    isPhotosPickerPresented = true
                                } label: {
                                    Image(systemName: "photo.on.rectangle")
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                } else {
                    ForEach(photos, id: \.data) { photo in
                        if let image = UIImage(data: photo.data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                        }
                    }
                    .onMove { sourceOffsets, destinationOffset in
                        photos.move(fromOffsets: sourceOffsets, toOffset: destinationOffset)
                    }
                    .onDelete { offsets in
                        photos.remove(atOffsets: offsets)
                    }
                }
            }
            .photosPicker(
                isPresented: $isPhotosPickerPresented,
                selection: $photosPickerItems,
                selectionBehavior: .ordered,
                matching: .images
            )
            .cookleImagePlayground(
                isPresented: $isImagePlaygroundPresented,
                recipe: recipe
            ) { data in
                photos.append(
                    .init(
                        data: data.compressed(),
                        source: .imagePlayground
                    )
                )
            }
        } header: {
            Text("Photos")
        }
        .onChange(of: photosPickerItems) {
            photos = recipe?.photos?.map { photo in
                .init(data: photo.data, source: .photosPicker)
            } ?? .empty
            Task {
                for item in photosPickerItems {
                    guard let data = try? await item.loadTransferable(type: Data.self) else {
                        continue
                    }
                    photos.append(.init(data: data.compressed(), source: .photosPicker))
                }
            }
        }
    }

    init(_ photos: Binding<[PhotoData]>) {
        _photos = photos
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photos: [Photo]
    Form {
        RecipeFormPhotosSection(
            .constant(photos.map { photo in
                .init(data: photo.data, source: photo.source)
            })
        )
    }
}
