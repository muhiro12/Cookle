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
            Text(diary.recipes.orEmpty.map(\.name).joined(separator: ", "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        } icon: {
            VStack {
                Text(diary.date.formatted(.dateTime.weekday()))
                    .font(.caption.bold().monospaced())
                    .textCase(.uppercase)
                    .foregroundStyle(.tint)
                Text(diary.date.formatted(.dateTime.day(.twoDigits)))
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
        .alert("Delete \(diary.date.formatted(.dateTime.year().month().day()))", isPresented: $isDeletePresented) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                diary.delete()
            }
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
