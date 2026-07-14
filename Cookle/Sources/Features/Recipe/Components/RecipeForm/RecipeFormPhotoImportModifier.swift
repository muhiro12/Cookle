import Foundation
import PhotosUI
import SwiftUI

struct RecipeFormPhotoImportModifier: ViewModifier {
    nonisolated struct Loader: Sendable {
        static let live = Self { item in
            try await item.loadTransferable(
                type: Data.self
            )
        }

        private let operation: @Sendable (PhotosPickerItem) async throws -> Data?

        init(
            operation: @escaping @Sendable (PhotosPickerItem) async throws -> Data?
        ) {
            self.operation = operation
        }

        func data(
            for item: PhotosPickerItem
        ) async throws -> Data? {
            try await operation(item)
        }
    }

    nonisolated struct Summary: Equatable, Sendable {
        let successfulCount: Int
        let failedCount: Int

        var failure: Failure? {
            guard failedCount > .zero else {
                return nil
            }

            guard successfulCount > .zero else {
                return .all(
                    failedCount: failedCount
                )
            }

            return .partial(
                successfulCount: successfulCount,
                failedCount: failedCount
            )
        }
    }

    nonisolated enum Failure: Equatable, Sendable {
        case all(failedCount: Int)
        case partial(
                successfulCount: Int,
                failedCount: Int
             )
    }

    private enum ImportOutcome {
        case cancelled
        case completed(Summary)
    }

    private struct ImportRequest {
        let id = UUID()
        let items: [PhotosPickerItem]
    }

    @Environment(\.isEnabled)
    private var isEnabled

    @Binding private var photos: [PhotoData]
    @Binding private var isPhotosPickerPresented: Bool

    @State private var photosPickerItems = [PhotosPickerItem]()
    @State private var importRequest: ImportRequest?
    @State private var activeImportID: UUID?
    @State private var importFailure: Failure?

    private let loader: Loader

    private var isImportingPhotos: Bool {
        activeImportID != nil
    }

    private var isImportFailurePresented: Binding<Bool> {
        .init(
            get: {
                importFailure != nil
            },
            set: { isPresented in
                if isPresented == false {
                    importFailure = nil
                }
            }
        )
    }

    private var importFailureTitle: Text {
        switch importFailure {
        case .all:
            Text("Could Not Add Photos")
        case .partial:
            Text("Some Photos Could Not Be Added")
        case nil:
            Text(verbatim: "")
        }
    }

    private var importFailureMessage: Text {
        switch importFailure {
        case .all(let failedCount):
            Text(
                "Added: 0. Could not load: \(failedCount). Try selecting the photos again."
            )
        case let .partial(successfulCount, failedCount):
            Text(
                """
                Added: \(successfulCount). Could not load: \(failedCount). \
                Try selecting the missing photos again.
                """
            )
        case nil:
            Text(verbatim: "")
        }
    }

    init(
        photos: Binding<[PhotoData]>,
        isPhotosPickerPresented: Binding<Bool>,
        loader: Loader
    ) {
        _photos = photos
        _isPhotosPickerPresented = isPhotosPickerPresented
        self.loader = loader
    }

    func body(content: Content) -> some View {
        content
            .disabled(isImportingPhotos)
            .photosPicker(
                isPresented: $isPhotosPickerPresented,
                selection: $photosPickerItems,
                selectionBehavior: .ordered,
                matching: .images
            )
            .onChange(of: photosPickerItems) {
                queueSelectedPhotos()
            }
            .onChange(of: isEnabled) {
                guard isEnabled == false else {
                    return
                }

                cancelImport()
            }
            .onDisappear {
                cancelImport()
            }
            .task(id: importRequest?.id) {
                guard let importRequest else {
                    return
                }

                await importPhotos(
                    for: importRequest
                )
            }
            .alert(
                importFailureTitle,
                isPresented: isImportFailurePresented
            ) {
                Button("OK", role: .cancel) {
                    importFailure = nil
                }
            } message: {
                importFailureMessage
            }
    }
}

private extension RecipeFormPhotoImportModifier {
    func queueSelectedPhotos() {
        guard photosPickerItems.isEmpty == false else {
            return
        }

        importFailure = nil
        importRequest = .init(
            items: photosPickerItems
        )
        photosPickerItems = []
    }

    func cancelImport() {
        isPhotosPickerPresented = false
        photosPickerItems = []
        importRequest = nil
    }

    @MainActor
    private func importPhotos(
        for request: ImportRequest
    ) async {
        activeImportID = request.id
        defer {
            finishImport(
                requestID: request.id
            )
        }

        let outcome = await loadSelectedPhotos(
            request.items
        )
        guard case .completed(let summary) = outcome else {
            return
        }

        importFailure = summary.failure
    }

    @MainActor
    private func loadSelectedPhotos(
        _ items: [PhotosPickerItem]
    ) async -> ImportOutcome {
        var successfulCount = 0
        var failedCount = 0

        for item in items {
            guard Task.isCancelled == false,
                  isEnabled else {
                return .cancelled
            }

            do {
                guard let data = try await loader.data(
                    for: item
                ) else {
                    failedCount += 1
                    continue
                }
                guard Task.isCancelled == false,
                      isEnabled else {
                    return .cancelled
                }

                guard try await appendImportedPhoto(
                    data
                ) else {
                    return .cancelled
                }
                successfulCount += 1
            } catch is CancellationError {
                guard Task.isCancelled == false,
                      isEnabled else {
                    return .cancelled
                }

                failedCount += 1
            } catch {
                guard Task.isCancelled == false,
                      isEnabled else {
                    return .cancelled
                }

                failedCount += 1
            }
        }

        guard Task.isCancelled == false,
              isEnabled else {
            return .cancelled
        }

        return .completed(
            .init(
                successfulCount: successfulCount,
                failedCount: failedCount
            )
        )
    }

    @MainActor
    private func appendImportedPhoto(
        _ data: Data
    ) async throws -> Bool {
        let compressedData = try await CooklePhotoImageCompressor.compressedData(
            from: data
        )
        guard Task.isCancelled == false,
              isEnabled else {
            return false
        }

        photos.append(
            .init(
                data: compressedData,
                source: .photosPicker
            )
        )
        return true
    }

    func finishImport(
        requestID: UUID
    ) {
        if activeImportID == requestID {
            activeImportID = nil
        }
        if importRequest?.id == requestID {
            importRequest = nil
        }
    }
}
