/// Why an otherwise well-formed export file cannot be read by this version of Cookle.
public enum CookleDataArchiveVersionError: Error, Equatable, Sendable {
    /// The file was exported from a newer data schema; updating Cookle may read it.
    case newerSchemaVersion(String)
}
