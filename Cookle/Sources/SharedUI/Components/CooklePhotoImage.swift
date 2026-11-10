import CoreGraphics
import MHUI
import SwiftUI

struct CooklePhotoImage: View {
    @Environment(\.mhDesignMetrics)
    private var designMetrics

    private let data: Data
    private let roundsCorners: Bool
    private let request: CooklePhotoImageRequest
    private let pipeline: CooklePhotoImagePipeline

    @State private var image: CGImage?

    var body: some View {
        Group {
            if let image {
                Image(
                    image,
                    scale: 1,
                    orientation: .up,
                    label: Text("Photo")
                )
                .resizable()
                .scaledToFit()
            } else {
                ZStack {
                    Color.clear
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .aspectRatio(1, contentMode: .fit)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Photo"))
            }
        }
        .clipShape(.rect(cornerRadius: roundsCorners ? designMetrics.cornerRadius.control : 0))
        .task(id: taskID) {
            image = nil
            let loadedImage = await pipeline.image(
                for: request,
                data: data
            )
            guard Task.isCancelled == false else {
                return
            }
            image = loadedImage
        }
    }

    init(
        data: Data,
        identity: CooklePhotoImageRequest.Identity,
        size: CooklePhotoImageRequest.Size,
        roundsCorners: Bool = true,
        pipeline: CooklePhotoImagePipeline = .shared
    ) {
        self.data = data
        self.roundsCorners = roundsCorners
        self.request = .init(
            identity: identity,
            size: size
        )
        self.pipeline = pipeline
    }
}

private extension CooklePhotoImage {
    nonisolated struct TaskID: Equatable, Sendable {
        let request: CooklePhotoImageRequest
        let data: Data
    }

    var taskID: TaskID {
        .init(
            request: request,
            data: data
        )
    }
}
