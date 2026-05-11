import UIKit
import Vision

/// Text recognition utility using Vision.
public enum TextRecognitionService {
    /// Recognizes text lines from a `UIImage`.
    /// - Parameter image: Source image.
    /// - Returns: Joined text lines separated by newlines.
    public static func recognize(in image: UIImage) throws -> String {
        guard let cgImage = image.cgImage else {
            return ""
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])
        let texts = request.results?.compactMap { $0.topCandidates(1).first?.string }
        return texts?.joined(separator: "\n") ?? ""
    }
}
