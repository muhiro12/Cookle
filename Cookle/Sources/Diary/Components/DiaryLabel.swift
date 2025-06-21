//
//  DiaryLabel.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/30/24.
//

import SwiftUI

struct DiaryLabel: View {
    @Environment(Diary.self) private var diary

    @State private var isEditPresented = false
    @State private var isDeletePresented = false

    var body: some View {
        Label {
            VStack(alignment: .leading) {
                LazyVGrid(columns: [.init(.adaptive(minimum: 80))], alignment: .leading) {
                    ForEach(
                        diary.recipes.orEmpty.compactMap {
                            $0.photoObjects.orEmpty.min()?.photo
                        }
                    ) { photo in
                        if let image = UIImage(data: photo.data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
                Text(diary.recipes.orEmpty.map(\.name).joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            VStack {
                Text(diary.date.formatted(.dateTime.weekday()))
                    .font(.caption.bold().monospaced())
                    .textCase(.uppercase)
                    .foregroundStyle(.tint)
                Text(diary.date.formatted(.dateTime.day(.twoDigits).locale(.init(identifier: "en_US"))))
                    .font(.title2.monospacedDigit())
            }
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
                diary.delete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
        .sheet(isPresented: $isEditPresented) {
            DiaryFormNavigationView()
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            DiaryLabel()
                .environment(preview.diaries[0])
        }
    }
}
