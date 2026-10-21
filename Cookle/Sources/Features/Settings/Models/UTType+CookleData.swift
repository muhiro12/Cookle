import UniformTypeIdentifiers

extension UTType {
    /// A Cookle data export: a package holding `manifest.json` and a `photos` folder.
    nonisolated static let cookleData = UTType(
        exportedAs: "com.muhiro12.Cookle.data",
        conformingTo: .package
    )
}
