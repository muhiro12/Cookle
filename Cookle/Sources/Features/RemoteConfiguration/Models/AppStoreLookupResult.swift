struct AppStoreLookupResult: Decodable {
    private enum CodingKeys: String, CodingKey {
        case trackID = "trackId"
        case bundleID = "bundleId"
        case version
    }

    let trackID: Int
    let bundleID: String
    let version: String
}
