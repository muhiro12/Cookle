import MHUI
import SwiftUI

struct DiaryTodaySection: View {
    private static let photoSize: CGFloat = 72
    private static let summaryLineLimit = 3

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize
    @Environment(\.mhTheme)
    private var theme

    let diaries: [Diary]
    let date: Date
    @Binding var selection: Diary?

    var body: some View {
        MHGroupedRows {
            if diaries.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.inline) {
                    Text("A dish name or a few words is enough to start.")
                        .foregroundStyle(.secondary)
                    AddDiaryButton()
                }
            }
            ForEach(diaries) { diary in
                Button {
                    $selection.cookleSelectForNavigation(diary)
                } label: {
                    summary(for: diary)
                        .cookleButtonRowContent()
                }
                .buttonStyle(.plain)
            }
        }
        .mhSection(
            title: Text("Today's Table"),
            supporting: Text(
                date,
                format: .dateTime.month().day().weekday()
            )
        )
    }
}

private extension DiaryTodaySection {
    func summary(for diary: Diary) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.content) {
            if !dynamicTypeSize.isAccessibilitySize,
               let photo = diary.recipes?.compactMap(\.primaryPhoto).first {
                CooklePhotoImage(data: photo.data, identity: .stored(photo.persistentModelID), size: .thumbnail)
                    .frame(width: Self.photoSize, height: Self.photoSize)
                    .clipped()
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: theme.spacing.inline) {
                if let recipes = diary.recipes, !recipes.isEmpty {
                    Text(recipes.map(\.name).joined(separator: ", "))
                        .lineLimit(Self.summaryLineLimit)
                }
                if !diary.note.isEmpty {
                    Text(diary.note)
                        .foregroundStyle(.secondary)
                        .lineLimit(Self.summaryLineLimit)
                }
                Label("View Today's Diary", systemImage: "chevron.right")
                    .foregroundStyle(.tint)
                    .font(.subheadline)
            }
        }
    }
}
