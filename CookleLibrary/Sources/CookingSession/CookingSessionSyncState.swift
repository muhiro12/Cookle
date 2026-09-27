import Foundation

/// The cooking session state one device shares with its paired peer.
///
/// `retiredThrough` is the terminal record: for each origin install it holds
/// the highest start sequence that has ended or been replaced. A retired
/// session never becomes active again, whatever its timestamps say. Entries
/// are one integer per install and are never pruned, so a delayed replay of a
/// retired session stays rejected across new starts and relaunches.
public struct CookingSessionSyncState: Codable, Equatable, Sendable {
    private struct FormatHeader: Decodable {
        let formatVersion: Int
    }

    /// The format this build writes and understands.
    public static let supportedFormatVersion = 1

    /// The format this state was written with.
    public let formatVersion: Int
    /// The most recent session this device knows, active or ended.
    public var current: CookingSessionRecord?
    /// The highest retired start sequence per origin install.
    public var retiredThrough: [String: Int]
    /// Reviewed conflict choices, separate from irrevocable end records.
    public var resolutions: [CookingSessionResolution]

    public init(
        current: CookingSessionRecord? = nil,
        retiredThrough: [String: Int] = [:],
        resolutions: [CookingSessionResolution] = []
    ) {
        self.formatVersion = Self.supportedFormatVersion
        self.current = current
        self.retiredThrough = retiredThrough
        self.resolutions = resolutions
    }

    /// Whether the session ended or was replaced.
    public func isRetired(
        _ sessionID: CookingSessionID
    ) -> Bool {
        sessionID.sequence <= retiredThrough[sessionID.originID, default: .zero]
    }

    /// Whether the record is active and not retired.
    public func isLive(
        _ record: CookingSessionRecord
    ) -> Bool {
        record.snapshot.isActive && isRetired(record.sessionID) == false
            && resolutions.contains { $0.excludes(record.sessionID) } == false
    }

    mutating func retire(
        _ sessionID: CookingSessionID
    ) {
        retiredThrough[sessionID.originID] = max(
            retiredThrough[sessionID.originID, default: .zero],
            sessionID.sequence
        )
    }

    /// Records that a known session implies every earlier start from the same
    /// origin already ended or was replaced on that origin.
    mutating func retirePredecessors(
        of sessionID: CookingSessionID
    ) {
        retiredThrough[sessionID.originID] = max(
            retiredThrough[sessionID.originID, default: .zero],
            sessionID.sequence - 1
        )
    }

    mutating func recordResolution(_ resolution: CookingSessionResolution) {
        if let index = resolutions.firstIndex(where: { $0.matches(resolution) }) {
            if resolution.supersedes(resolutions[index]) {
                resolutions[index] = resolution
            }
        } else {
            resolutions.append(resolution)
        }
    }

    mutating func absorbRetirements(
        from other: Self
    ) {
        retiredThrough.merge(other.retiredThrough) { lhs, rhs in
            max(lhs, rhs)
        }
        for resolution in other.resolutions {
            recordResolution(resolution)
        }
        let retirementMap = retiredThrough
        resolutions.removeAll { resolution in
            resolution.first.sequence <= retirementMap[resolution.first.originID, default: .zero]
                && resolution.second.sequence <= retirementMap[resolution.second.originID, default: .zero]
        }
    }
}

public extension CookingSessionSyncState {
    /// The result of decoding a peer's encoded state.
    enum Decoding: Equatable, Sendable {
        /// A readable state.
        case decoded(CookingSessionSyncState)
        /// A newer format than this build understands.
        case unsupported
        /// Unreadable data.
        case malformed
    }

    internal var isValid: Bool {
        formatVersion == Self.supportedFormatVersion
            && (current?.isValid ?? true)
            && retiredThrough.allSatisfy { origin, sequence in
                !origin.isEmpty && sequence >= .zero && sequence < CookingSessionID.maximumCounter
            }
            && resolutions.allSatisfy(\.isValid)
    }

    /// Decodes a peer's state, separating newer formats from unreadable data.
    static func decoding(
        _ value: String
    ) -> Decoding {
        guard let data = value.data(using: .utf8) else {
            return .malformed
        }
        guard let header = try? JSONDecoder().decode(
            FormatHeader.self,
            from: data
        ) else {
            return .malformed
        }
        guard header.formatVersion <= supportedFormatVersion else {
            return .unsupported
        }
        guard header.formatVersion == supportedFormatVersion,
              let state = try? JSONDecoder().decode(Self.self, from: data),
              state.isValid else {
            return .malformed
        }
        return .decoded(state)
    }

    /// Encodes this state for storage or transport.
    func encodedString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else {
            return nil
        }
        return String(
            data: data,
            encoding: .utf8
        )
    }
}
