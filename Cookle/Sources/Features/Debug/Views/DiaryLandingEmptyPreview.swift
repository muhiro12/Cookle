#if DEBUG
import SwiftData
import SwiftUI

struct DiaryLandingEmptyPreview: View {
    private static let assembly: CookleAppAssembly = {
        do {
            let container = try ModelContainer(
                for: Recipe.self,
                configurations: .init(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            )
            return CookleAppAssemblyFactory.preview(modelContainer: container)
        } catch {
            fatalError("Failed to prepare empty Diary preview: \(error)")
        }
    }()

    var body: some View {
        NavigationStack {
            DiaryListView()
        }
        .cooklePreviewAppAssembly(Self.assembly)
    }
}

#Preview("Empty diary landing") {
    DiaryLandingEmptyPreview()
}
#endif
