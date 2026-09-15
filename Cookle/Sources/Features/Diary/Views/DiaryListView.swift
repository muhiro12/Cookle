import MHPlatform
import MHUI
import SwiftData
import SwiftUI

struct DiaryListView: View {
    private static let recentDiaryCount = 3

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
            ToolbarItem {
                AddDiaryButton()
            }
            ToolbarItem {
                if isPresented {
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
        let recent = Array(
            history.filter { $0.date < Calendar.current.startOfDay(for: date) }
                .prefix(Self.recentDiaryCount)
        )
        let recentIDs = Set(recent.map(\.id))
        let remainingIDs = Set(history.filter { !recentIDs.contains($0.id) }.map(\.id))
        let groups = Dictionary(grouping: diaries) { $0.date.formatted(.dateTime.year().month()) }
            .sorted { $0.value[0].date > $1.value[0].date }
        if !recent.isEmpty {
            Section("Recent Meals") {
                diaryRows(recent)
            }
        }
        ForEach(groups, id: \.key) { group in
            let rows = group.value.filter { remainingIDs.contains($0.id) }
            if !rows.isEmpty {
                Section(group.key) {
                    diaryRows(rows)
                }
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
