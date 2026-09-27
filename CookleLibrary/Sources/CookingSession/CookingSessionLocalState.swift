import Foundation

/// The durable cooking session state owned by one install.
///
/// Every local change is applied here and persisted before it is sent, and
/// every received peer state is merged here. Ordering uses session identity,
/// logical revisions, and retirement records only; wall-clock timestamps keep
/// their timer meanings but never decide which state wins.
public struct CookingSessionLocalState: Codable, Equatable, Sendable {
    /// The per-install identifier used as origin and editor identity.
    public let originID: String
    /// The state shared with the peer.
    public private(set) var shared: CookingSessionSyncState
    /// A different live session started independently on the peer, kept until
    /// the user chooses between it and the local session.
    public private(set) var pendingConflict: CookingSessionRecord?
    /// The last start sequence this install used.
    public private(set) var lastStartedSequence: Int

    public var activeRecord: CookingSessionRecord? {
        guard let current = shared.current,
              shared.isLive(current) else {
            return nil
        }
        return current
    }

    public var activeSnapshot: CookingSessionSnapshot? {
        activeRecord?.snapshot
    }

    public init(
        originID: String = UUID().uuidString,
        shared: CookingSessionSyncState = .init(),
        pendingConflict: CookingSessionRecord? = nil,
        lastStartedSequence: Int = .zero
    ) {
        self.originID = originID
        self.shared = shared
        self.pendingConflict = pendingConflict
        self.lastStartedSequence = lastStartedSequence
    }

    /// Creates local state from a snapshot saved by an earlier build.
    ///
    /// An active legacy snapshot becomes a new local session so it can be
    /// recovered; an ended one is not revived.
    public static func migrating(
        legacySnapshot: CookingSessionSnapshot?,
        originID: String = UUID().uuidString
    ) -> Self {
        var state = Self(originID: originID)
        if let legacySnapshot,
           legacySnapshot.isActive {
            state.start(legacySnapshot)
        }
        return state
    }

    /// Starts a new session, retiring every session this install knows.
    public mutating func start(
        _ snapshot: CookingSessionSnapshot
    ) {
        if let current = shared.current {
            shared.retire(current.sessionID)
        }
        if let pendingConflict {
            shared.retire(pendingConflict.sessionID)
        }
        pendingConflict = nil
        let sequence = max(
            lastStartedSequence,
            shared.retiredThrough[originID, default: .zero]
        ) + 1
        lastStartedSequence = sequence
        let sessionID = CookingSessionID(
            originID: originID,
            sequence: sequence
        )
        shared.retirePredecessors(of: sessionID)
        shared.current = .init(
            sessionID: sessionID,
            revision: 1,
            editorID: originID,
            snapshot: snapshot
        )
    }

    /// Applies a local edit to the active session. Returns `false` when there
    /// is no active session or the edit changes nothing.
    @discardableResult
    public mutating func updateActiveSession(
        _ transform: (CookingSessionSnapshot) -> CookingSessionSnapshot
    ) -> Bool {
        guard let activeRecord else {
            return false
        }
        let updatedSnapshot = transform(activeRecord.snapshot)
        guard updatedSnapshot != activeRecord.snapshot else {
            return false
        }
        guard updatedSnapshot.isActive else {
            return endActiveSession(updatedAt: updatedSnapshot.updatedAt)
        }
        shared.current = activeRecord.revised(
            with: updatedSnapshot,
            editorID: originID
        )
        return true
    }

    /// Ends the active session. A pending peer session, if any, becomes the
    /// current session because it is still live on the peer.
    @discardableResult
    public mutating func endActiveSession(
        updatedAt: Date = .now
    ) -> Bool {
        guard let activeRecord else {
            return false
        }
        shared.current = activeRecord.revised(
            with: activeRecord.snapshot.endingSession(updatedAt: updatedAt),
            editorID: originID
        )
        shared.retire(activeRecord.sessionID)
        promotePendingConflictIfNeeded()
        return true
    }

    /// Resolves a pending conflict. Keeping the local session retires the
    /// peer session; switching retires the local session and adopts the peer's.
    @discardableResult
    public mutating func resolveConflict(
        keepingLocalSession: Bool
    ) -> Bool {
        guard let pendingConflict else {
            return false
        }
        self.pendingConflict = nil
        if keepingLocalSession {
            shared.retire(pendingConflict.sessionID)
        } else {
            if let current = shared.current {
                shared.retire(current.sessionID)
            }
            shared.current = pendingConflict
        }
        normalize()
        return true
    }

    /// Merges a peer's shared state. Returns `true` when local state changed.
    @discardableResult
    public mutating func merge(
        _ incoming: CookingSessionSyncState
    ) -> Bool {
        let original = self
        shared.absorbRetirements(from: incoming)
        for record in [shared.current, pendingConflict, incoming.current].compactMap(\.self) {
            shared.retirePredecessors(of: record.sessionID)
        }

        if let incomingRecord = incoming.current {
            if let current = shared.current,
               current.sessionID == incomingRecord.sessionID {
                if incomingRecord.supersedes(current) {
                    shared.current = incomingRecord
                }
            } else if let pendingConflict,
                      pendingConflict.sessionID == incomingRecord.sessionID {
                if incomingRecord.supersedes(pendingConflict) {
                    self.pendingConflict = incomingRecord
                }
            } else if shared.isLive(incomingRecord) {
                if activeRecord == nil {
                    shared.current = incomingRecord
                } else {
                    pendingConflict = incomingRecord
                }
            }
        }

        normalize()
        return self != original
    }
}

private extension CookingSessionLocalState {
    mutating func promotePendingConflictIfNeeded() {
        guard activeRecord == nil,
              let pendingConflict,
              shared.isLive(pendingConflict) else {
            return
        }
        shared.current = pendingConflict
        self.pendingConflict = nil
    }

    mutating func normalize() {
        promotePendingConflictIfNeeded()
        if let pendingConflict,
           shared.isLive(pendingConflict) == false
            || pendingConflict.sessionID == shared.current?.sessionID {
            self.pendingConflict = nil
        }
    }
}

public extension CookingSessionLocalState {
    /// Decodes persisted local state.
    static func decoded(
        from value: String
    ) -> Self? {
        guard let data = value.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(
            Self.self,
            from: data
        )
    }

    /// Encodes local state for persistence.
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
