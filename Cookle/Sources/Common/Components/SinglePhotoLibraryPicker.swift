import Foundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct SinglePhotoLibraryPicker: UIViewControllerRepresentable {
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
    ) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(
        _: PHPickerViewController,
        context _: Context
    ) {
        // no-op
    }

    func makeCoordinator() -> Coordinator {
        .init(parent: self)
    }
}

extension SinglePhotoLibraryPicker {
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: SinglePhotoLibraryPicker

        init(parent: SinglePhotoLibraryPicker) {
            self.parent = parent
        }

        func picker(
            _: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            guard let result = results.first else {
                parent.cancellationHandler()
                parent.dismiss()
                return
            }

            let provider = result.itemProvider
            guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
                parent.cancellationHandler()
                parent.dismiss()
                return
            }

            provider.loadDataRepresentation(
                forTypeIdentifier: UTType.image.identifier
            ) { data, _ in
                DispatchQueue.main.async {
                    guard let data else {
                        self.parent.cancellationHandler()
                        self.parent.dismiss()
                        return
                    }

                    self.parent.completionHandler(data)
                    self.parent.dismiss()
                }
            }
        }
    }
}
