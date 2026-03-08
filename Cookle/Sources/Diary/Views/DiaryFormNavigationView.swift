import SwiftUI

struct DiaryFormNavigationView: View {
    var body: some View {
        NavigationStack {
            DiaryFormView()
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    DiaryFormNavigationView()
}
