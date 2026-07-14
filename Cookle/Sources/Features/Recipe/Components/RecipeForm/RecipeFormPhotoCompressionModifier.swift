import Foundation
import SwiftUI

struct RecipeFormPhotoCompressionModifier: ViewModifier {
    nonisolated struct Request: Identifiable, Sendable {
        let id = UUID()
        let data: Data
        let source: PhotoSource
    }

    @Binding private var photos: [PhotoData]
    @Binding private var request: Request?
    @State private var sessionID = UUID()

    init(
        photos: Binding<[PhotoData]>,
        request: Binding<Request?>
    ) {
        _photos = photos
        _request = request
    }

    func body(content: Content) -> some View {
        content
            .onDisappear {
                sessionID = UUID()
                request = nil
            }
            .task(id: request?.id) {
                guard let request else {
                    return
                }

                await compressAndAppendPhoto(
                    for: request,
                    sessionID: sessionID
                )
            }
    }
}

private extension RecipeFormPhotoCompressionModifier {
    func compressAndAppendPhoto(
        for request: RecipeFormPhotoCompressionModifier.Request,
        sessionID: UUID
    ) async {
        do {
            let compressedData = try await CooklePhotoImageCompressor.compressedData(
                from: request.data
            )
            try Task.checkCancellation()
            guard self.request?.id == request.id,
                  self.sessionID == sessionID else {
                return
            }

            photos.append(
                .init(
                    data: compressedData,
                    source: request.source
                )
            )
            self.request = nil
        } catch is CancellationError {
            // Cancellation invalidates this input without changing the draft.
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}
