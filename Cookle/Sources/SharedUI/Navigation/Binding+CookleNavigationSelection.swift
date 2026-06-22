import SwiftData
import SwiftUI

extension Binding {
    func cookleSelectForNavigation<Model: PersistentModel>(
        _ model: Model
    ) where Value == Model? {
        guard wrappedValue?.persistentModelID == model.persistentModelID else {
            wrappedValue = model
            return
        }

        wrappedValue = nil
        Task { @MainActor in
            wrappedValue = model
        }
    }
}
