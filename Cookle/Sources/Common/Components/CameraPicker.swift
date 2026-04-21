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
        cancellationHandler: @escaping () -> Void = {}
    ) {
        self.completionHandler = completionHandler
        self.cancellationHandler = cancellationHandler
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

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
                parent.cancellationHandler()
                parent.dismiss()
                return
            }

            parent.completionHandler(data)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(
            _: UIImagePickerController
        ) {
            parent.cancellationHandler()
            parent.dismiss()
        }
    }
}
