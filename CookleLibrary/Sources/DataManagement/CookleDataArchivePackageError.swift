import Foundation

enum CookleDataArchivePackageError: LocalizedError, Sendable {
    case unsupportedPackageFormatVersion(Int)
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
        case .unsupportedPackageFormatVersion(let version):
            "Unsupported backup package format version: \(version)"
        case .invalidPhotoFilename(let filename):
            "Backup contains an invalid photo filename: \(filename)"
        case .duplicatePhotoFilename(let filename):
            "Backup contains a duplicate photo filename: \(filename)"
        case .missingPhotoFile(let filename):
            "Backup is missing a photo file: \(filename)"
        case .unexpectedPhotoFile(let filename):
            "Backup contains an unexpected photo file: \(filename)"
        case let .invalidPhotoByteCount(
            filename,
            byteCount
        ):
            "Backup photo \(filename) declares an invalid byte count: \(byteCount)"
        case let .photoByteCountMismatch(
            filename,
            expectedByteCount,
            actualByteCount
        ):
            """
            Backup photo \(filename) contains \(actualByteCount) bytes instead of \(expectedByteCount) bytes.
            """
        case .invalidPhotoDigest(let filename):
            "Backup photo \(filename) declares an invalid SHA-256 digest."
        case .photoDigestMismatch(let filename):
            "Backup photo \(filename) does not match its SHA-256 digest."
        }
    }
}
