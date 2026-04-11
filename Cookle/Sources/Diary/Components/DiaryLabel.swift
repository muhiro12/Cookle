//
//  DiaryLabel.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/30/24.
//

import SwiftData
import SwiftUI

struct DiaryLabel: View {
    private enum Layout {
        static let photoGridMinimum = CGFloat(Int("80") ?? .zero)
        static let titleLineLimit = Int("2") ?? .zero
        static let iconWidth = CGFloat(Int("28") ?? .zero)
    }

    @Environment(Diary.self)
    private var diary
    @Environment(\.modelContext)
    private var context
    @Environment(DiaryActionService.self)
    private var diaryActionService

    @State private var isEditPresented = false
    @State private var isDeletePresented = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    var body: some View {
        Label {
            VStack(alignment: .leading) {
                LazyVGrid(columns: [.init(.adaptive(minimum: Layout.photoGridMinimum))], alignment: .leading) {
                    ForEach(
                        diary.recipes.orEmpty.compactMap(\.primaryPhoto)
                    ) { photo in
                        if let image = UIImage(data: photo.data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .accessibilityHidden(true)
                        }
                    }
                }
                Text(DiaryListSummary.text(
                    recipeNames: diary.recipes.orEmpty.map(\.name),
                    note: diary.note
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(Layout.titleLineLimit)
            }
        } icon: {
            VStack {
                Text(diary.date.formatted(.dateTime.weekday()))
                    .font(.caption.bold().monospaced())
                    .textCase(.uppercase)
                    .foregroundStyle(.tint)
                Text(diary.date.formatted(.dateTime.day(.twoDigits).locale(.init(identifier: "en_US"))))
                    .font(.title2.monospacedDigit())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: Layout.iconWidth)
            .foregroundStyle(Color(uiColor: .label))
        }
        .contextMenu {
            EditDiaryButton {
                isEditPresented = true
            }
            DeleteDiaryButton {
                isDeletePresented = true
            }
        }
        .confirmationDialog(
            Text("Delete \(diary.date.formatted(.dateTime.year().month().day()))"),
            isPresented: $isDeletePresented
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        _ = try await diaryActionService.delete(
                            context: context,
                            diary: diary
                        )
                    } catch {
                        errorMessage = error.localizedDescription
                        isErrorPresented = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
        .alert(
            Text("Cannot Delete Diary"),
            isPresented: $isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                // Dismisses the alert.
            }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $isEditPresented) {
            DiaryFormNavigationView()
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var diaries: [Diary]
    List {
        DiaryLabel()
            .environment(diaries[0])
    }
}
