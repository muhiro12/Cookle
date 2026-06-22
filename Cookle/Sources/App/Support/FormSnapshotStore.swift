import Foundation
import MHPlatform

struct FormSnapshotStore<Snapshot: Codable & Sendable> {
    private let store: MHPreferenceStore
    private let descriptor: MHCodablePreferenceDescriptor<Snapshot>

    init(
        descriptor: MHCodablePreferenceDescriptor<Snapshot>,
        userDefaults: UserDefaults? = nil
    ) {
        if let userDefaults {
            store = .init(userDefaults: userDefaults)
        } else {
            store = .init()
        }
        self.descriptor = descriptor
    }

    func snapshot() -> Snapshot? {
        store.codable(for: descriptor)
    }

    func hasSnapshot() -> Bool {
        snapshot() != nil
    }

    func saveSnapshot(
        _ snapshot: Snapshot
    ) {
        store.setCodable(
            snapshot,
            for: descriptor
        )
    }

    func removeSnapshot() {
        store.remove(descriptor)
    }
}
