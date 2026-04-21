import SwiftUI

struct DiaryFormNavigationView: View {
    private let prefill: DiaryFormPrefill?

    var body: some View {
        NavigationStack {
            DiaryFormView(
                prefill: prefill
            )
        }
    }

    init(
        prefill: DiaryFormPrefill? = nil
    ) {
        self.prefill = prefill
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    DiaryFormNavigationView()
}
