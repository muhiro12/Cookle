import Foundation

struct FormSnapshotStore<Snapshot: Codable> {
    private let userDefaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(
        userDefaults: UserDefaults = .standard
    ) {
        self.userDefaults = userDefaults
    }

    func snapshot(
        for key: String
    ) -> Snapshot? {
        let storageKey = storageKey(
            for: key
        )
        guard let storedValue = userDefaults.string(
            forKey: storageKey
        ) else {
            return nil
        }
        guard let data = storedValue.data(
            using: .utf8
        ) else {
            userDefaults.removeObject(
                forKey: storageKey
            )
            return nil
        }

        do {
            return try decoder.decode(
                Snapshot.self,
                from: data
            )
        } catch {
            userDefaults.removeObject(
                forKey: storageKey
            )
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
        guard let data = try? encoder.encode(
            snapshot
        ),
        let value = String(
            data: data,
            encoding: .utf8
        ) else {
            return
        }

        userDefaults.set(
            value,
            forKey: storageKey(
                for: key
            )
        )
    }

    func removeSnapshot(
        for key: String
    ) {
        userDefaults.removeObject(
            forKey: storageKey(
                for: key
            )
        )
    }
}

private extension FormSnapshotStore {
    func storageKey(
        for key: String
    ) -> String {
        "cookle.formSnapshot.\(key)"
    }
}
