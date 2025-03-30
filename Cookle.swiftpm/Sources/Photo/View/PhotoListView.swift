//
//  PhotoListView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import SwiftData
import SwiftUI
import SwiftUtilities

struct PhotoListView: View {
    @Environment(\.isPresented) private var isPresented

    @Query(.photos(.sourceIs(.photosPicker))) private var photos: [Photo]
    @Query(.photos(.sourceIs(.imagePlayground))) private var imagePlaygrounds: [Photo]

    @Binding private var photo: Photo?

    init(selection: Binding<Photo?> = .constant(nil)) {
        _photo = selection
    }

    var body: some View {
        Group {
            if photos.isNotEmpty {
                ScrollView {
                    ForEach([photos, imagePlaygrounds], id: \.first?.source) { photos in
                        VStack {
                            Text(photos[0].source.description)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                            LazyVGrid(columns: [.init(.adaptive(minimum: 120))]) {
                                ForEach(photos) { photo in
                                    if photo.recipes.isNotEmpty,
                                       let image = UIImage(data: photo.data) {
                                        NavigationLink(value: photo) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                AddRecipeButton()
            }
        }
        .navigationTitle(Text("Photos"))
        .toolbar {
            ToolbarItem {
                AddRecipeButton()
            }
            ToolbarItem {
                CloseButton()
                    .hidden(!isPresented)
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            PhotoListView()
        }
    }
}
