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
        static let previewImageHeight = CGFloat(Int("240") ?? .zero)
    }

    @Environment(Photo.self)
    private var photo

    @Binding private var recipe: Recipe?

    @State private var isPhotoDetailPresented = false

    var body: some View {
        List(selection: $recipe) {
            previewSection
            recipeSection
            createdAtSection
            updatedAtSection
        }
        .navigationTitle(photo.title)
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
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .listRowBackground(EmptyView())
            }
        }
    }

    var recipeSection: some View {
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

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photos: [Photo]
    PhotoView()
        .environment(photos[0])
}
