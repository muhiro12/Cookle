import SwiftUI

struct DiaryFormNavigationView: View {
    private let prefill: DiaryFormPrefill?
    private let persistsDraft: Bool

    var body: some View {
        NavigationStack {
            DiaryFormView(
                prefill: prefill,
                persistsDraft: persistsDraft
            )
        }
        .recipeFormPresentationHost()
    }

    init(
        prefill: DiaryFormPrefill? = nil,
        persistsDraft: Bool = true
    ) {
        self.prefill = prefill
        self.persistsDraft = persistsDraft
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    DiaryFormNavigationView()
}
