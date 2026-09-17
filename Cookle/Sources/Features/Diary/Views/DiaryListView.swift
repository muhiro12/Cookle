import MHPlatform
import MHUI
import SwiftData
import SwiftUI

struct DiaryListView: View {
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(\.isPresented)
    private var isPresented
    @Environment(MainNavigationModel.self)
    private var navigationModel

    @Query(.diaries(.all))
    private var diaries: [Diary]
    @Query(sort: [SortDescriptor(\Recipe.modifiedTimestamp, order: .reverse), SortDescriptor(\Recipe.name)])
    private var recipes: [Recipe]

    @Binding private var diary: Diary?
    @State private var currentDate = Date.now

    var body: some View {
        List {
            DuplicateDiaryRepairSection()
            DiaryTodaySection(
                diaries: todayDiaries(on: currentDate),
                date: currentDate,
                selection: $diary
            )
            DiaryRecipeInspirationSection(recipes: recipes) { recipe in
                navigationModel.selectedRecipe = recipe
                navigationModel.selectedTab = .recipe
            }
            historySections(on: currentDate)
        }
        .mhListChrome()
        .onAppear {
            currentDate = .now
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                currentDate = .now
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            currentDate = .now
        }
        .cookleTopLevelNavigationChrome("Diaries")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                AddDiaryButton()
            }
            if isPresented {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton()
                }
            }
        }
    }

    init(selection: Binding<Diary?> = .constant(nil)) {
        _diary = selection
    }
}

private extension DiaryListView {
    func todayDiaries(on date: Date) -> [Diary] {
        diaries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    @ViewBuilder
    func historySections(on date: Date) -> some View {
        let history = diaries.filter { !Calendar.current.isDate($0.date, inSameDayAs: date) }
        let groups = Dictionary(grouping: history) { $0.date.formatted(.dateTime.year().month()) }
            .sorted { $0.value[0].date > $1.value[0].date }
        ForEach(groups, id: \.key) { group in
            Section(group.key) {
                diaryRows(group.value)
            }
            AdvertisementSection(.small)
        }
    }

    func diaryRows(_ rows: [Diary]) -> some View {
        ForEach(rows) { row in
            Button {
                $diary.cookleSelectForNavigation(row)
            } label: {
                DiaryLabel()
                    .environment(row)
                    .cookleButtonRowContent()
            }
            .buttonStyle(.plain)
        }
    }
}

#if DEBUG
#Preview("Diary landing") {
    NavigationStack {
        DiaryListView()
    }
    .cooklePreviewAppAssembly(DiaryRecipeSelectionPreview.assembly)
}
#Preview("Diary landing in app navigation") {
    MainView()
        .cooklePreviewAppAssembly(DiaryRecipeSelectionPreview.assembly)
}
#endif
