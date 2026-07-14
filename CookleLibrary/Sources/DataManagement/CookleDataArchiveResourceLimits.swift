struct CookleDataArchiveResourceLimits: Sendable {
    private enum Standard {
        static let bytesPerKibibyte = 1_024
        static let kibibytesPerMebibyte = 1_024
        static let maximumEncodedMebibytes = 64
        static let maximumTopLevelRecordCountPerCategory = 10_000
        static let maximumAggregateNestedRecordCount = 100_000
        static let maximumIdentifierKibibytes = 1
        static let maximumTextKibibytes = 64
        static let maximumPhotoMebibytes = 10
        static let maximumAggregatePhotoMebibytes = 40

        static let bytesPerMebibyte = bytesPerKibibyte * kibibytesPerMebibyte
    }

    static let standard: Self = .init(
        maximumEncodedByteCount: Standard.maximumEncodedMebibytes * Standard.bytesPerMebibyte,
        maximumTopLevelRecordCountPerCategory: Standard.maximumTopLevelRecordCountPerCategory,
        maximumAggregateNestedRecordCount: Standard.maximumAggregateNestedRecordCount,
        maximumIdentifierByteCount: Standard.maximumIdentifierKibibytes * Standard.bytesPerKibibyte,
        maximumTextByteCount: Standard.maximumTextKibibytes * Standard.bytesPerKibibyte,
        maximumPhotoByteCount: Standard.maximumPhotoMebibytes * Standard.bytesPerMebibyte,
        maximumAggregatePhotoByteCount: Standard.maximumAggregatePhotoMebibytes * Standard.bytesPerMebibyte
    )

    let maximumEncodedByteCount: Int
    let maximumTopLevelRecordCountPerCategory: Int
    let maximumAggregateNestedRecordCount: Int
    let maximumIdentifierByteCount: Int
    let maximumTextByteCount: Int
    let maximumPhotoByteCount: Int
    let maximumAggregatePhotoByteCount: Int
}
