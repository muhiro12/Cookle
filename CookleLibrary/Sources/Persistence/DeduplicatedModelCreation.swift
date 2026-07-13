enum DeduplicatedModelCreation {
    static func resolve<Model>(
        fetchExisting: () throws -> Model?,
        createNew: () -> Model
    ) rethrows -> Model {
        if let existingModel = try fetchExisting() {
            return existingModel
        }
        return createNew()
    }
}
