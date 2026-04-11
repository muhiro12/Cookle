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
        static let actionButtonPadding = CGFloat(Int("8") ?? .zero)
    }

    @Environment(Recipe.self)
    private var recipe
    @Environment(\.modelContext)
    private var context
    @Environment(RecipeActionService.self)
    private var recipeActionService

    @State private var selectedPhoto: Photo?
    @State private var pendingPhotoObject: PhotoObject?
    @State private var isPhotoRemovalDialogPresented = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    var body: some View {
        if let photoObjects = recipe.photoObjects,
           photoObjects.isNotEmpty {
            Section {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(photoObjects.sorted()) { photoObject in
                            photoTile(for: photoObject)
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
            .confirmationDialog(
                Text(photoRemovalTitle),
                isPresented: $isPhotoRemovalDialogPresented
            ) {
                if let pendingPhotoObject {
                    Button(photoRemovalTitle, role: .destructive) {
                        removePhoto(pendingPhotoObject)
                    }
                }
                Button("Cancel", role: .cancel) {
                    pendingPhotoObject = nil
                }
            } message: {
                Text(photoRemovalMessage)
            }
            .alert(
                Text("Cannot Remove Photo"),
                isPresented: $isErrorPresented
            ) {
                Button("OK", role: .cancel) {
                    // Dismisses the alert.
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

private extension RecipePhotosSection {
    var photoRemovalTitle: String {
        guard let pendingPhotoObject else {
            return "Remove Photo"
        }

        if removesUnderlyingAsset(for: pendingPhotoObject) {
            return "Delete Photo"
        }

        return "Detach from Recipe"
    }

    var photoRemovalMessage: String {
        guard let pendingPhotoObject else {
            return ""
        }

        if removesUnderlyingAsset(for: pendingPhotoObject) {
            return """
                This photo is only linked to \(recipe.name). Deleting it removes \
                the relation and the stored photo asset.
                """
        }

        return """
            This removes the photo from \(recipe.name) and keeps the stored photo \
            anywhere else it is still linked.
            """
    }

    @ViewBuilder
    func photoTile(for photoObject: PhotoObject) -> some View {
        if let photo = photoObject.photo,
           let image = UIImage(data: photo.data) {
            ZStack(alignment: .topTrailing) {
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

                Menu {
                    Button(role: .destructive) {
                        pendingPhotoObject = photoObject
                        isPhotoRemovalDialogPresented = true
                    } label: {
                        if removesUnderlyingAsset(for: photoObject) {
                            Label("Delete Photo", systemImage: "trash")
                        } else {
                            Label("Detach from Recipe", systemImage: "link.badge.minus")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .padding(Layout.actionButtonPadding)
                        .background(.thinMaterial, in: .circle)
                }
                .accessibilityLabel(Text("Photo Actions"))
                .padding(Layout.actionButtonPadding)
            }
        }
    }

    func removesUnderlyingAsset(
        for photoObject: PhotoObject
    ) -> Bool {
        photoObject.photo?.objects.orEmpty.count == 1
    }

    func removePhoto(
        _ photoObject: PhotoObject
    ) {
        pendingPhotoObject = nil

        Task {
            do {
                _ = try await recipeActionService.removePhoto(
                    context: context,
                    recipe: recipe,
                    photoObject: photoObject
                )
            } catch {
                errorMessage = error.localizedDescription
                isErrorPresented = true
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
