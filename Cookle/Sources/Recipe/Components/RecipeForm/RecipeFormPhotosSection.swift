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
    private enum Layout {
        static let viewModePhotoHeight = CGFloat(Int("120") ?? .zero)
        static let editModePhotoHeight = CGFloat(Int("80") ?? .zero)
    }

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
            photoSectionContent
        } header: {
            Text("Photos")
        }
        .onChange(of: photosPickerItems) {
            applySelectedPhotoItems()
        }
    }

    var photoSectionContent: some View {
        Group {
            if editMode?.wrappedValue == .inactive {
                viewModeContent
            } else {
                editModeContent
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
    }

    var viewModeContent: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                photoThumbnails(height: Layout.viewModePhotoHeight)
                addPhotoControl
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }

    var editModeContent: some View {
        ForEach(photos, id: \.data) { photo in
            if let image = UIImage(data: photo.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text("Selected Photo"))
                    .frame(height: Layout.editModePhotoHeight)
            }
        }
        .onMove { sourceOffsets, destinationOffset in
            photos.move(fromOffsets: sourceOffsets, toOffset: destinationOffset)
        }
        .onDelete { offsets in
            photos.remove(atOffsets: offsets)
        }
    }

    @ViewBuilder var addPhotoControl: some View {
        if CookleImagePlayground.isSupported {
            Menu {
                Button {
                    isPhotosPickerPresented = true
                } label: {
                    Label {
                        Text("Choose Photo")
                    } icon: {
                        Image(systemName: "photo.on.rectangle")
                            .accessibilityHidden(true)
                    }
                }
                Button {
                    isImagePlaygroundPresented = true
                } label: {
                    Label {
                        Text("Image Playground")
                    } icon: {
                        Image(systemName: "apple.image.playground")
                            .accessibilityHidden(true)
                    }
                }
            } label: {
                Image(systemName: "photo.badge.plus")
                    .accessibilityLabel(Text("Add Photo"))
            }
        } else {
            Button {
                isPhotosPickerPresented = true
            } label: {
                Image(systemName: "photo.on.rectangle")
                    .accessibilityLabel(Text("Choose Photo"))
            }
        }
    }

    init(_ photos: Binding<[PhotoData]>) {
        _photos = photos
    }

    @ViewBuilder
    func photoThumbnails(height: CGFloat) -> some View {
        ForEach(photos, id: \.data) { photo in
            if let image = UIImage(data: photo.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text("Selected Photo"))
                    .frame(height: height)
            }
        }
    }

    func applySelectedPhotoItems() {
        photos = recipe?.photos?.map { photo in
            .init(data: photo.data, source: .photosPicker)
        } ?? .empty
        Task {
            for item in photosPickerItems {
                guard let data = try? await item.loadTransferable(type: Data.self) else {
                    continue
                }
                photos.append(
                    .init(
                        data: data.compressed(),
                        source: .photosPicker
                    )
                )
            }
        }
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
