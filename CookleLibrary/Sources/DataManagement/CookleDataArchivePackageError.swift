import Foundation

enum CookleDataArchivePackageError: LocalizedError, Sendable {
    case unsupportedFormat(String)
    case unsupportedFormatVersion(Int)
    case unsupportedSchemaVersion(String)
    case invalidPhotoFilename(String)
    case duplicatePhotoFilename(String)
    case missingPhotoFile(String)
    case unexpectedPhotoFile(String)
    case invalidPhotoByteCount(
            filename: String,
            byteCount: Int
         )
    case photoByteCountMismatch(
            filename: String,
            expectedByteCount: Int,
            actualByteCount: Int
         )
    case invalidPhotoDigest(String)
    case photoDigestMismatch(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            "Unsupported export file format: \(format)"
        case .unsupportedFormatVersion(let version):
            "Unsupported export file format version: \(version)"
        case .unsupportedSchemaVersion(let version):
            "Unsupported export file schema version: \(version)"
        case .invalidPhotoFilename(let filename):
            "Export file contains an invalid photo filename: \(filename)"
        case .duplicatePhotoFilename(let filename):
            "Export file contains a duplicate photo filename: \(filename)"
        case .missingPhotoFile(let filename):
            "Export file is missing a photo file: \(filename)"
        case .unexpectedPhotoFile(let filename):
            "Export file contains an unexpected photo file: \(filename)"
        case let .invalidPhotoByteCount(
            filename,
            byteCount
        ):
            "Exported photo \(filename) declares an invalid byte count: \(byteCount)"
        case let .photoByteCountMismatch(
            filename,
            expectedByteCount,
            actualByteCount
        ):
            """
            Exported photo \(filename) contains \(actualByteCount) bytes instead of \(expectedByteCount) bytes.
            """
        case .invalidPhotoDigest(let filename):
            "Exported photo \(filename) declares an invalid SHA-256 digest."
        case .photoDigestMismatch(let filename):
            "Exported photo \(filename) does not match its SHA-256 digest."
        }
    }
}
