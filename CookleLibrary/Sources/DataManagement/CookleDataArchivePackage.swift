import Foundation

/// Portable version 2 backup package with photo payloads stored outside its manifest.
public struct CookleDataArchivePackage: Sendable {
    /// One photo payload stored in the package's `photos` directory.
    public struct PhotoFile: Sendable {
        /// Exporter-assigned package filename.
        public let filename: String
        /// Original persisted photo bytes.
        public let data: Data

        public init(
            filename: String,
            data: Data
        ) {
            self.filename = filename
            self.data = data
        }
    }

    /// Required root filename for the encoded package manifest.
    public static let manifestFilename = "manifest.json"
    /// Required root directory name for photo payloads.
    public static let photosDirectoryName = "photos"

    /// Encoded `manifest.json` contents.
    public let manifestData: Data
    /// Photo payloads that belong in the package's `photos` directory.
    public let photoFiles: [PhotoFile]

    public init(
        manifestData: Data,
        photoFiles: [PhotoFile]
    ) {
        self.manifestData = manifestData
        self.photoFiles = photoFiles
    }
}
