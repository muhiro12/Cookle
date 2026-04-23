//
//  PhotoView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import SwiftData
import SwiftUI

struct PhotoView: View {
    private enum Layout {
        static let previewImageHeight: CGFloat = 240
    }

    @Environment(Photo.self)
    private var photo

    @Binding private var photoSelection: Photo?
    @Binding private var recipe: Recipe?

    @State private var isPhotoDetailPresented = false

    var body: some View {
        List {
            previewSection
            recipeSection
            createdAtSection
            updatedAtSection
            actionSection
        }
        .navigationTitle(
            PhotoDisplayCopy.title(for: photo)
        )
        .fullScreenCover(isPresented: $isPhotoDetailPresented) {
            PhotoDetailNavigationView(photos: [photo])
        }
    }

    var previewSection: some View {
        Section {
            if let image = UIImage(data: photo.data) {
                Button {
                    isPhotoDetailPresented = true
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(Text("Open Photo"))
                        .frame(height: Layout.previewImageHeight)
                        .cookleButtonRowContent(alignment: .center)
                }
                .buttonStyle(.plain)
                .listRowBackground(EmptyView())
            }
        }
    }

    var recipeSection: some View {
        Section {
            if photo.recipes.orEmpty.isEmpty {
                Text("Not linked to any recipe.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(photo.recipes.orEmpty) { rowRecipe in
                    Button {
                        $recipe.cookleSelectForNavigation(
                            rowRecipe
                        )
                    } label: {
                        RecipeLabel()
                            .labelStyle(.titleOnly)
                            .environment(rowRecipe)
                            .cookleButtonRowContent()
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Recipes")
        }
    }

    var createdAtSection: some View {
        Section {
            Text(photo.createdTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Created At")
        }
    }

    var updatedAtSection: some View {
        Section {
            Text(photo.modifiedTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Updated At")
        }
    }

    var actionSection: some View {
        Section {
            DeletePhotoButton {
                photoSelection = nil
            }
        } header: {
            Spacer()
        }
    }

    init(
        photoSelection: Binding<Photo?> = .constant(nil),
        recipeSelection: Binding<Recipe?> = .constant(nil)
    ) {
        _photoSelection = photoSelection
        _recipe = recipeSelection
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photos: [Photo]
    PhotoView()
        .environment(photos[0])
}
