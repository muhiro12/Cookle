import Foundation
import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    typealias CompletionHandler = (Data) -> Void

    @Environment(\.dismiss)
    private var dismiss

    private let completionHandler: CompletionHandler
    private let cancellationHandler: () -> Void

    init(
        completionHandler: @escaping CompletionHandler,
        cancellationHandler: @escaping () -> Void = {
            // Intentionally empty.
        }
    ) {
        self.completionHandler = completionHandler
        self.cancellationHandler = cancellationHandler
    }

    static func dismantleUIViewController(
        _: UIImagePickerController,
        coordinator: Coordinator
    ) {
        coordinator.cancelPendingWork()
    }

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {
        let controller: UIImagePickerController = .init()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        controller.allowsEditing = false
        return controller
    }

    func updateUIViewController(
        _: UIImagePickerController,
        context _: Context
    ) {
        // no-op
    }

    func makeCoordinator() -> Coordinator {
        .init(parent: self)
    }
}

extension CameraPicker {
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraPicker
        private var encodingTask: Task<Void, Never>?
        private var activeEncodingID: UUID?
        private var hasResolvedSelection = false

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard beginResolvingSelection() else {
                return
            }

            guard let image = info[.originalImage] as? UIImage,
                  let imageSource = CameraImageEncoder.Source(image: image) else {
                finishWithCancellation()
                return
            }

            let encodingID = UUID()
            activeEncodingID = encodingID
            encodingTask = Task { [weak self] in
                let data = await CameraImageEncoder.data(
                    from: imageSource
                )
                guard Task.isCancelled == false else {
                    return
                }

                self?.finishEncoding(
                    id: encodingID,
                    data: data
                )
            }
        }

        func imagePickerControllerDidCancel(
            _: UIImagePickerController
        ) {
            guard beginResolvingSelection() else {
                return
            }

            finishWithCancellation()
        }

        func cancelPendingWork() {
            guard hasResolvedSelection == false || activeEncodingID != nil else {
                return
            }

            hasResolvedSelection = true
            activeEncodingID = nil
            encodingTask?.cancel()
            encodingTask = nil
        }

        private func beginResolvingSelection() -> Bool {
            guard hasResolvedSelection == false else {
                return false
            }

            hasResolvedSelection = true
            return true
        }

        private func finishEncoding(
            id: UUID,
            data: Data?
        ) {
            guard activeEncodingID == id else {
                return
            }

            activeEncodingID = nil
            encodingTask = nil
            guard let data else {
                finishWithCancellation()
                return
            }

            parent.completionHandler(data)
            parent.dismiss()
        }

        private func finishWithCancellation() {
            activeEncodingID = nil
            encodingTask?.cancel()
            encodingTask = nil
            parent.cancellationHandler()
            parent.dismiss()
        }
    }
}
