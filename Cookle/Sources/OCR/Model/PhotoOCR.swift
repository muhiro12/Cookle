//
//  PhotoOCR.swift
//  Cookle
//
//  Created by Codex on 2025/06/05.
//

import UIKit
import Vision

enum PhotoOCR {
    static func recognize(from data: Data) throws -> [String] {
        guard let image = UIImage(data: data)?.cgImage else {
            return []
        }
        let request = VNRecognizeTextRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        try handler.perform([request])
        return request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
    }
}
