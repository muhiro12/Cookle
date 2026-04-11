import Foundation
import MHPlatform

struct FormSnapshotStore<Snapshot: Codable & Sendable> {
    private let store: MHPreferenceStore
    private let userDefaults: UserDefaults
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard
    ) {
        store = .init(userDefaults: userDefaults)
        self.userDefaults = userDefaults
    }

    func snapshot(
        for key: String
    ) -> Snapshot? {
        let preferenceKey = preferenceKey(
            for: key
        )
        if let snapshot = store.codable(
            for: preferenceKey
        ) {
            return snapshot
        }

        guard let storedValue = userDefaults.object(
            forKey: preferenceKey.storageKey
        ) else {
            return nil
        }

        guard let legacyValue = storedValue as? String else {
            store.remove(preferenceKey)
            return nil
        }

        let data = Data(
            legacyValue.utf8
        )
        do {
            let snapshot = try decoder.decode(
                Snapshot.self,
                from: data
            )
            store.setCodable(
                snapshot,
                for: preferenceKey
            )
            return snapshot
        } catch {
            store.remove(preferenceKey)
            return nil
        }
    }

    func hasSnapshot(
        for key: String
    ) -> Bool {
        snapshot(for: key) != nil
    }

    func saveSnapshot(
        _ snapshot: Snapshot,
        for key: String
    ) {
        store.setCodable(
            snapshot,
            for: preferenceKey(
                for: key
            )
        )
    }

    func removeSnapshot(
        for key: String
    ) {
        store.remove(
            preferenceKey(
                for: key
            )
        )
    }
}

private extension FormSnapshotStore {
    func preferenceKey(
        for key: String
    ) -> MHCodablePreferenceKey<Snapshot> {
        CodablePreferenceNamespace.formSnapshot.preferenceKey(
            name: key,
            Snapshot.self
        )
    }
}
