import Vision
import UIKit

extension UIImage {
    func recognizedText() -> String {
        guard let cgImage = cgImage else { return "" }
        let request = VNRecognizeTextRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
        return request.results?
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n") ?? ""
    }
}
