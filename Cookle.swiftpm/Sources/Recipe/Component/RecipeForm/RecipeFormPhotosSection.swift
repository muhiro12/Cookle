//
//  RecipeFormPhotosSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import ImagePlayground
import PhotosUI
import SwiftUI

struct RecipeFormPhotosSection: View {
    @Environment(Recipe.self) private var recipe: Recipe?
    @Environment(\.editMode) private var editMode

    @Binding private var photos: [Data]

    @State private var photosPickerItems = [PhotosPickerItem]()
    @State private var isPhotosPickerPresented = false
    @State private var isImagePlaygroundPresented = false

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
                        if #available(iOS 18.1, *),
                           EnvironmentValues().supportsImagePlayground {
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
                            .imagePlaygroundSheet(
                                isPresented: $isImagePlaygroundPresented,
                                concepts: {
                                    var concepts = [ImagePlaygroundConcept]()
                                    recipe?.ingredients?.forEach { ingredient in
                                        concepts.append(
                                            .extracted(
                                                from: ingredient.value,
                                                title: recipe?.name
                                            )
                                        )
                                    }
                                    recipe?.steps.forEach { step in
                                        concepts.append(
                                            .extracted(
                                                from: step,
                                                title: recipe?.name
                                            )
                                        )
                                    }
                                    return concepts
                                }()
                            ) { url in
                                guard let data = try? Data(contentsOf: url) else {
                                    return
                                }
                                photos.append(data.compressed())
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
        .photosPicker(
            isPresented: $isPhotosPickerPresented,
            selection: $photosPickerItems,
            selectionBehavior: .ordered,
            matching: .images
        )
        .onChange(of: photosPickerItems) {
            photos = (recipe?.photos).orEmpty.map(\.data)
            Task {
                for item in photosPickerItems {
                    guard let data = try? await item.loadTransferable(type: Data.self) else {
                        continue
                    }
                    photos.append(data.compressed())
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
