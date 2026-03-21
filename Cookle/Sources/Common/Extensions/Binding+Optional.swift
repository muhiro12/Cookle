import SwiftUI

extension Binding {
    func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        .init(
            get: {
                wrappedValue != nil
            },
            set: { isPresented in
                if !isPresented {
                    wrappedValue = nil
                }
            }
        )
    }
}
