import SwiftUI

struct RecipeDiaryRow: View {
    @Environment(CookleRouteNavigator.self)
    private var routeNavigator

    let diary: Diary

    var body: some View {
        Button {
            openDiary(diary)
        } label: {
            Text(diary.date.formatted(.dateTime.year().month().day()))
                .fixedSize(horizontal: false, vertical: true)
                .cookleButtonRowContent()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Show Diary")
    }
}

private extension RecipeDiaryRow {
    func openDiary(_ diary: Diary) {
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: diary.date
        )
        guard let year = dateComponents.year,
              let month = dateComponents.month,
              let day = dateComponents.day else {
            routeNavigator.open(.diary)
            return
        }
        routeNavigator.open(
            .diaryDate(
                year: year,
                month: month,
                day: day
            )
        )
    }
}
