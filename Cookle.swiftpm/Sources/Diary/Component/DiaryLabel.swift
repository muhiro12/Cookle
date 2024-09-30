//
//  DiaryLabel.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/30/24.
//

import SwiftUI

struct DiaryLabel: View {
    @Environment(Diary.self) private var diary

    var body: some View {
        Label {
            Text(diary.recipes.orEmpty.map { $0.name }.joined(separator: ", "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        } icon: {
            VStack {
                Text(diary.date.formatted(.dateTime.weekday()))
                    .font(.caption.monospaced())
                Text(diary.date.formatted(.dateTime.day(.twoDigits)))
                    .font(.title2.monospacedDigit())
            }
            .foregroundStyle(Color(uiColor: .label))
        }
    }
}

#Preview {
    CooklePreview { preview in
        DiaryLabel()
            .environment(preview.diaries[0])
    }
}
