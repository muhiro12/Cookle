import SwiftData

extension ModelContext {
    func fetchFirst<Model>(
        _ descriptor: FetchDescriptor<Model>
    ) throws -> Model? where Model: PersistentModel {
        var descriptor = descriptor
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }
}
