//
//  PhotoNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI

struct PhotoNavigationView: View {
    @State private var photo: Photo?
    @State private var recipe: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            PhotoListView(selection: $photo)
                .navigationDestination(for: Photo.self) { photo in
                    PhotoView(selection: $recipe)
                        .environment(photo)
                }
        } content: {
            if let photo {
                PhotoView(selection: $recipe)
                    .environment(photo)
            }
        } detail: {
            if let recipe {
                RecipeView()
                    .environment(recipe)
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        PhotoNavigationView()
    }
}
