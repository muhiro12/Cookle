import Foundation
import MHUI
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
    @State private var photoRowIDs: [UUID]

    var body: some View {
        Section {
            photoSectionContent
        } header: {
            Text("Photos")
        }
        .onChange(of: photosPickerItems) {
            applySelectedPhotoItems()
        }
        .onAppear {
            synchronizePhotoRowIDs()
        }
        .onChange(of: photos.count) {
            synchronizePhotoRowIDs()
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
        ForEach(photoRows) { row in
            if let image = UIImage(data: photos[row.index].data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text("Selected Photo"))
                    .frame(height: Layout.editModePhotoHeight)
            }
        }
        .onMove { sourceOffsets, destinationOffset in
            movePhotos(
                fromOffsets: sourceOffsets,
                toOffset: destinationOffset
            )
        }
        .onDelete { offsets in
            deletePhotos(atOffsets: offsets)
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
        _photoRowIDs = State(
            initialValue: RecipeFormStableRowIDs.make(
                count: photos.wrappedValue.count
            )
        )
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

    var photoRows: [RecipeFormStableRowIDs.IndexedRow] {
        RecipeFormStableRowIDs.indexedRows(
            rowIDs: photoRowIDs,
            count: photos.count
        )
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
        guard pendingPhotoRemovalBehavior != nil else {
            return ""
        }
        return "Remove from Recipe"
    }

    var photoRemovalMessage: String {
        guard let recipe else {
            return ""
        }

        guard pendingPhotoRemovalBehavior != nil else {
            return ""
        }

        return """
            This removes the photo from \(recipe.name) and keeps the stored photo \
            in Photos.
            """
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
        ForEach(photoRows) { row in
            RecipeFormPhotoThumbnailView(
                photo: photos[row.index],
                index: row.index,
                height: height,
                cornerRadius: designMetrics.cornerRadius.control,
                actionButtonPadding: designMetrics.spacing.inline,
                photoRemovalBehavior: photoRemovalBehavior(
                    for: row.index
                ),
                pendingPhotoRemovalIndex: $pendingPhotoRemovalIndex,
                isPhotoRemovalDialogPresented: $isPhotoRemovalDialogPresented
            )
        }
    }

    func applySelectedPhotoItems() {
        guard !photosPickerItems.isEmpty else {
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
        guard let recipe else {
            return nil
        }

        return RecipeFormPhotoRemovalResolver(
            recipe: recipe,
            photos: photos
        )
        .behavior(for: index)
    }

    func removePhoto(at index: Int) {
        guard photos.indices.contains(index) else {
            return
        }

        pendingPhotoRemovalIndex = nil
        photos.remove(at: index)
        if photoRowIDs.indices.contains(index) {
            photoRowIDs.remove(at: index)
        }
    }

    func movePhotos(
        fromOffsets sourceOffsets: IndexSet,
        toOffset destinationOffset: Int
    ) {
        photos.move(
            fromOffsets: sourceOffsets,
            toOffset: destinationOffset
        )
        photoRowIDs.move(
            fromOffsets: sourceOffsets,
            toOffset: destinationOffset
        )
    }

    func deletePhotos(atOffsets offsets: IndexSet) {
        photos.remove(atOffsets: offsets)
        photoRowIDs.remove(atOffsets: offsets)
        clearStalePendingPhotoRemoval()
    }

    func synchronizePhotoRowIDs() {
        RecipeFormStableRowIDs.synchronize(
            &photoRowIDs,
            count: photos.count
        )
        clearStalePendingPhotoRemoval()
    }

    func clearStalePendingPhotoRemoval() {
        guard let pendingPhotoRemovalIndex,
              photos.indices.contains(pendingPhotoRemovalIndex) == false else {
            return
        }

        self.pendingPhotoRemovalIndex = nil
    }
}
