import SwiftUI

extension RecipePhotoInputSource {
    @ViewBuilder var label: some View {
        Label {
            titleText
        } icon: {
            Image(systemName: systemImageName)
                .accessibilityHidden(true)
        }
    }

    var titleText: Text {
        switch self {
        case .camera:
            Text("Camera")
        case .photoLibrary:
            Text("Photo Library")
        case .imagePlayground:
            Text("Image Playground")
        }
    }

    private var systemImageName: String {
        switch self {
        case .camera:
            "camera"
        case .photoLibrary:
            "photo"
        case .imagePlayground:
            "apple.image.playground"
        }
    }
}
