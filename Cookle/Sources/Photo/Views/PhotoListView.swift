//
//  PhotoListView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import SwiftData
import SwiftUI

struct PhotoListView: View {
    private enum Layout {
        static let photoGridMinimum: CGFloat = 120
    }

    @Environment(\.isPresented)
    private var isPresented

    @Query(.photos(.sourceIs(.photosPicker)))
    private var photos: [Photo]
    @Query(.photos(.sourceIs(.imagePlayground)))
    private var imagePlaygrounds: [Photo]

    @Binding private var photo: Photo?

    var body: some View {
        contentView()
            .cookleTopLevelNavigationChrome("Photos")
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

    init(selection: Binding<Photo?> = .constant(nil)) {
        _photo = selection
    }
}

private extension PhotoListView {
    var photoSectionsView: some View {
        ScrollView {
            ForEach(groupedPhotos, id: \.source.rawValue) { group in
                photoSection(for: group)
            }
        }
    }

    var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Photos Yet", systemImage: "photo.on.rectangle")
        } description: {
            Text("Add photos to browse them here.")
        } actions: {
            AddRecipeButton()
        }
    }

    var groupedPhotos: [(source: PhotoSource, photos: [Photo])] {
        [
            (
                source: .photosPicker,
                photos: photos
            ),
            (
                source: .imagePlayground,
                photos: imagePlaygrounds
            )
        ]
        .filter(\.photos.isNotEmpty)
    }

    @ViewBuilder
    func contentView() -> some View {
        if groupedPhotos.isNotEmpty {
            photoSectionsView
        } else {
            emptyStateView
        }
    }

    @ViewBuilder
    func photoSection(
        for group: (source: PhotoSource, photos: [Photo])
    ) -> some View {
        VStack {
            Text(group.source.description)
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            LazyVGrid(columns: [.init(.adaptive(minimum: Layout.photoGridMinimum))]) {
                ForEach(group.photos) { photo in
                    photoButton(for: photo)
                }
            }
        }
    }

    @ViewBuilder
    func photoButton(for photo: Photo) -> some View {
        if let image = UIImage(data: photo.data) {
            Button {
                self.photo = photo
            } label: {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text(photo.title))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        PhotoListView()
    }
}
