import SwiftData

extension PersistentModel {
    func delete() {
        modelContext?.delete(self)
    }
}
