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

    init(selection: Binding<Recipe?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                if let image = UIImage(data: photo.data) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(height: 240)
                }
            }
            Section {
                ForEach(photo.recipes.orEmpty, id: \.self) { recipe in
                    Text(recipe.name)
                }
            } header: {
                Text("Recipe")
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        PhotoView(selection: .constant(nil))
            .environment(preview.photos[0])
    }
}
