import MHDesign
import PhotosUI
import SwiftData
import SwiftUI
import TipKit

struct RecipeFormPhotosSection: View {
    private enum Layout {
        static let viewModePhotoHeight: CGFloat = 120
        static let editModePhotoHeight: CGFloat = 80
    }

    @Environment(Recipe.self)
    private var recipe: Recipe?
    @Environment(\.mhDesignMetrics)
    private var designMetrics
    @Environment(\.editMode)
    private var editMode
    @Binding private var photos: [PhotoData]
    private let addPhotoTip: (any Tip)?
    @State private var photosPickerItems = [PhotosPickerItem]()
    @State private var isPhotosPickerPresented = false
    @State private var isCameraPresented = false
    @State private var isImagePlaygroundPresented = false
    @State private var pendingPhotoRemovalIndex: Int?
    @State private var isPhotoRemovalDialogPresented = false

    var body: some View {
        Section {
            photoSectionContent
        } header: {
            Text("Photos")
        }
        .onChange(of: photosPickerItems) {
            applySelectedPhotoItems()
        }
        .confirmationDialog(
            Text(photoRemovalTitle),
            isPresented: $isPhotoRemovalDialogPresented
        ) {
            if let pendingPhotoRemovalIndex {
                Button(photoRemovalTitle, role: .destructive) {
                    removePhoto(
                        at: pendingPhotoRemovalIndex
                    )
                }
            }
            Button("Cancel", role: .cancel) {
                pendingPhotoRemovalIndex = nil
            }
        } message: {
            Text(photoRemovalMessage)
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
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker { data in
                appendCapturedPhoto(data)
            }
        }
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
        Group {
            if photos.isEmpty {
                addPhotoRow
            } else {
                ScrollView(.horizontal) {
                    LazyHStack {
                        photoThumbnails(
                            height: Layout.viewModePhotoHeight
                        )
                        addPhotoControl
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
            }
        }
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

    var addPhotoControl: some View {
        Menu {
            photoInputSourceButtons
        } label: {
            Image(systemName: "photo.badge.plus")
                .accessibilityLabel(Text("Add Photo"))
        }
        .cooklePopoverTip(
            addPhotoTip,
            arrowEdge: .top
        )
    }

    init(
        _ photos: Binding<[PhotoData]>,
        addPhotoTip: (any Tip)? = nil
    ) {
        _photos = photos
        self.addPhotoTip = addPhotoTip
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photos: [Photo]
    Form {
        RecipeFormPhotosSection(.constant(photos.map { photo in
            .init(data: photo.data, source: photo.source)
        }))
    }
}

#Preview("Empty", traits: .modifier(CookleSampleData())) {
    Form {
        RecipeFormPhotosSection(.constant([]))
    }
}

private extension RecipeFormPhotosSection {
    var availablePhotoInputSources: [RecipePhotoInputSource] {
        RecipePhotoInputSource.allCases.filter(\.isAvailable)
    }

    var addPhotoRow: some View {
        Menu {
            photoInputSourceButtons
        } label: {
            Label {
                Text("Add Photo")
            } icon: {
                Image(systemName: "photo.badge.plus")
                    .accessibilityHidden(true)
            }
            .cookleButtonRowContent()
        }
        .buttonStyle(.plain)
        .cooklePopoverTip(
            addPhotoTip,
            arrowEdge: .top
        )
    }

    @ViewBuilder var photoInputSourceButtons: some View {
        ForEach(availablePhotoInputSources) { source in
            Button {
                presentPhotoInputSource(source)
            } label: {
                source.label
            }
        }
    }

    var photoRemovalTitle: String {
        switch pendingPhotoRemovalBehavior {
        case .deletePhoto:
            return "Delete Photo"
        case .detachFromRecipe:
            return "Detach from Recipe"
        case nil:
            return ""
        }
    }

    var photoRemovalMessage: String {
        guard let recipe else {
            return ""
        }

        switch pendingPhotoRemovalBehavior {
        case .deletePhoto:
            return """
                This photo is only linked to \(recipe.name). Deleting it removes \
                the relation and the stored photo asset.
                """
        case .detachFromRecipe:
            return """
                This removes the photo from \(recipe.name) and keeps the stored photo \
                anywhere else it is still linked.
                """
        case nil:
            return ""
        }
    }

    var pendingPhotoRemovalBehavior: RecipePhotoRemovalBehavior? {
        guard let pendingPhotoRemovalIndex else {
            return nil
        }

        return photoRemovalBehavior(
            for: pendingPhotoRemovalIndex
        )
    }

    @ViewBuilder
    func photoThumbnails(height: CGFloat) -> some View {
        ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
            RecipeFormPhotoThumbnailView(
                photo: photo,
                index: index,
                height: height,
                cornerRadius: designMetrics.cornerRadius.control,
                actionButtonPadding: designMetrics.spacing.inline,
                photoRemovalBehavior: photoRemovalBehavior(
                    for: index
                ),
                pendingPhotoRemovalIndex: $pendingPhotoRemovalIndex,
                isPhotoRemovalDialogPresented: $isPhotoRemovalDialogPresented
            )
        }
    }

    func applySelectedPhotoItems() {
        guard photosPickerItems.isNotEmpty else {
            return
        }

        let selectedItems = photosPickerItems
        photosPickerItems = []
        Task {
            for item in selectedItems {
                guard let data = try? await item.loadTransferable(
                    type: Data.self
                ) else {
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

    func presentPhotoInputSource(
        _ source: RecipePhotoInputSource
    ) {
        switch source {
        case .camera:
            isCameraPresented = true
        case .photoLibrary:
            isPhotosPickerPresented = true
        case .imagePlayground:
            isImagePlaygroundPresented = true
        }
    }

    func appendCapturedPhoto(
        _ data: Data
    ) {
        photos.append(
            .init(
                data: data.compressed(),
                source: .photosPicker
            )
        )
    }

    func photoRemovalBehavior(for index: Int) -> RecipePhotoRemovalBehavior? {
        guard let recipe,
              let persistedPhotoObject = persistedPhotoObject(
                for: index
              ) else {
            return nil
        }

        return .persistedPhotoBehavior(
            draftReferenceCount: draftReferenceCount(
                for: index
            ),
            persistedReferenceCountOutsideRecipe:
                persistedReferenceCountOutsideRecipe(
                    for: persistedPhotoObject,
                    recipe: recipe
                )
        )
    }

    func persistedPhotoObject(for index: Int) -> PhotoObject? {
        guard let recipe else {
            return nil
        }

        let photoData = photos[index]
        let matchingPhotoObjects = recipe.orderedPhotoObjects.filter { photoObject in
            guard let photo = photoObject.photo else {
                return false
            }

            return photo.data == photoData.data
                && photo.source == photoData.source
        }
        let matchingDraftCount = photos.prefix(
            index + 1
        )
        .filter { currentPhoto in
            currentPhoto.data == photoData.data
                && currentPhoto.source == photoData.source
        }
        .count

        guard matchingDraftCount <= matchingPhotoObjects.count else {
            return nil
        }

        return matchingPhotoObjects[matchingDraftCount - 1]
    }

    func draftReferenceCount(for index: Int) -> Int {
        let photoData = photos[index]
        return photos.filter { currentPhoto in
            currentPhoto.data == photoData.data
                && currentPhoto.source == photoData.source
        }
        .count
    }

    func persistedReferenceCountOutsideRecipe(
        for photoObject: PhotoObject,
        recipe: Recipe
    ) -> Int {
        guard let photo = photoObject.photo else {
            return .zero
        }

        let currentRecipeReferenceCount = recipe.orderedPhotoObjects
            .filter { currentPhotoObject in
                guard let currentPhoto = currentPhotoObject.photo else {
                    return false
                }

                return currentPhoto.data == photo.data
                    && currentPhoto.source == photo.source
            }
            .count
        let totalReferenceCount = photo.objects.orEmpty.count

        return max(
            .zero,
            totalReferenceCount - currentRecipeReferenceCount
        )
    }

    func removePhoto(at index: Int) {
        pendingPhotoRemovalIndex = nil
        photos.remove(at: index)
    }
}
