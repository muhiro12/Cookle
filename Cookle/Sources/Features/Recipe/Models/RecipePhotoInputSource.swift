import UIKit

enum RecipePhotoInputSource: CaseIterable, Identifiable, Sendable {
    case camera
    case photoLibrary
    case imagePlayground

    var id: Self {
        self
    }
}

extension RecipePhotoInputSource {
    var isAvailable: Bool {
        switch self {
        case .camera:
            #if targetEnvironment(simulator)
            false
            #else
            UIImagePickerController.isSourceTypeAvailable(.camera)
            #endif
        case .photoLibrary:
            true
        case .imagePlayground:
            CookleImagePlayground.isSupported
        }
    }

    var persistedPhotoSource: PhotoSource {
        switch self {
        case .camera,
             .photoLibrary:
            .photosPicker
        case .imagePlayground:
            .imagePlayground
        }
    }
}
