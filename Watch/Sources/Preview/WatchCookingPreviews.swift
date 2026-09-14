#if DEBUG
import SwiftUI

private struct WatchCookingPreviews: View {
    enum Data {
        private static let sampleTimestamp: TimeInterval = 1_789_344_000

        private static let sampleDate = Date(timeIntervalSince1970: sampleTimestamp)
        static var activeSnapshot: CookingSessionSnapshot {
            .init(
                recipeID: "watch-cooking-preview",
                recipeName: "きのこと春野菜のクリームパスタ",
                steps: [
                    "大きな鍋に湯を沸かして塩を加え、パスタを8分ゆでる。ときどき底からやさしく混ぜ、麺がくっつかないようにする。ゆで汁を少し取り分けてから湯を切り、ソースの入ったフライパンに移す。",
                    "きのこと春野菜を弱火で炒め、生クリームとゆで汁を加えて全体を混ぜる。",
                    "皿に盛り、黒こしょうとチーズをふって温かいうちに食べる。"
                ],
                currentStepIndex: .zero,
                activeTimer: nil,
                updatedAt: sampleDate,
                isActive: true
            )
        }
    }

    @StateObject private var cookingSessionStore: WatchCookingSessionStore

    private let showsTimerOnly: Bool

    var body: some View {
        Group {
            if showsTimerOnly,
               let snapshot = cookingSessionStore.activeSnapshot {
                ScrollView {
                    WatchCookingTimerSection(snapshot: snapshot)
                        .padding()
                }
            } else {
                ContentView()
            }
        }
        .environmentObject(cookingSessionStore)
        .environment(\.locale, Locale(identifier: "ja_JP"))
    }

    init(
        snapshot: CookingSessionSnapshot?,
        showsTimerOnly: Bool = false
    ) {
        _cookingSessionStore = StateObject(
            wrappedValue: WatchCookingSessionStore(previewSnapshot: snapshot)
        )
        self.showsTimerOnly = showsTimerOnly
    }
}

#Preview("Empty") {
    WatchCookingPreviews(snapshot: nil)
}

#Preview("Long Japanese Steps") {
    WatchCookingPreviews(snapshot: WatchCookingPreviews.Data.activeSnapshot)
}

#Preview("Timer Idle") {
    WatchCookingPreviews(
        snapshot: WatchCookingPreviews.Data.activeSnapshot,
        showsTimerOnly: true
    )
}

#Preview("Timer Running") {
    WatchCookingPreviews(
        snapshot: WatchCookingPreviews.Data.activeSnapshot.startingTimer(
            durationMinutes: 8
        ),
        showsTimerOnly: true
    )
}

#Preview("Timer Expired") {
    WatchCookingPreviews(
        snapshot: WatchCookingPreviews.Data.activeSnapshot.startingTimer(
            durationMinutes: 1,
            startedAt: .now.addingTimeInterval(-120)
        ),
        showsTimerOnly: true
    )
}
#endif
