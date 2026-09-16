//
//  PhotoListView.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import MHUI
import SwiftData
import SwiftUI

struct PhotoListView: View {
    private enum Layout {
        static let photoGridMinimum: CGFloat = 120
    }

    @Environment(\.isPresented)
    private var isPresented
    @Environment(\.mhTheme)
    private var theme

    @Query(.photos(.sourceIs(.photosPicker)))
    private var photos: [Photo]
    @Query(.photos(.sourceIs(.imagePlayground)))
    private var imagePlaygrounds: [Photo]

    @Binding private var photo: Photo?

    var body: some View {
        contentView()
            .cookleTopLevelNavigationChrome("Photos")
            .toolbar {
                if isPresented {
                    ToolbarItem(placement: .cancellationAction) {
                        CloseButton()
                    }
                }
            }
    }

    init(selection: Binding<Photo?> = .constant(nil)) {
        _photo = selection
    }
}

private extension PhotoListView {
    var photoSectionsView: some View {
        VStack(spacing: theme.spacing.section) {
            ForEach(groupedPhotos, id: \.source.rawValue) { group in
                photoSection(for: group)
            }
        }
        .mhScreen()
    }

    var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Photos Yet", systemImage: "photo.on.rectangle")
        } description: {
            Text("Start a recipe with just a name, then add photos when you are ready.")
        } actions: {
            AddRecipeButton(showsTitle: true)
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
        .filter { !$0.photos.isEmpty }
    }

    @ViewBuilder
    func contentView() -> some View {
        if !groupedPhotos.isEmpty {
            photoSectionsView
        } else {
            emptyStateView
        }
    }

    @ViewBuilder
    func photoSection(
        for group: (source: PhotoSource, photos: [Photo])
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.content) {
            MHSectionHeader(title: Text(group.source.description))
            LazyVGrid(columns: [.init(.adaptive(minimum: Layout.photoGridMinimum))]) {
                ForEach(group.photos) { photo in
                    photoButton(for: photo)
                }
            }
        }
    }

    @ViewBuilder
    func photoButton(for rowPhoto: Photo) -> some View {
        Button {
            $photo.cookleSelectForNavigation(
                rowPhoto
            )
        } label: {
            CooklePhotoImage(
                data: rowPhoto.data,
                identity: .stored(rowPhoto.persistentModelID),
                size: .thumbnail
            )
            .accessibilityLabel(
                Text(
                    PhotoDisplayCopy.title(for: rowPhoto)
                )
            )
            .cookleButtonRowContent(alignment: .center)
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        PhotoListView()
    }
}

#if DEBUG
#Preview("Empty photo collection") {
    if let container = try? ModelContainer(
        for: Recipe.self,
        configurations: .init(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    ) {
        NavigationStack {
            PhotoListView()
        }
        .cooklePreviewAppAssembly(CookleAppAssemblyFactory.preview(modelContainer: container))
    }
}
#endif
