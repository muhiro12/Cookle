//
//  DiaryView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI

struct DiaryView: View {
    @Environment(Diary.self) private var diary

    @Binding private var selection: Recipe?

    init(selection: Binding<Recipe?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Section("Date") {
                Text(diary.date.formatted(.dateTime.year().month().day()))
            }
            Section("Breakfasts") {
                ForEach(diary.breakfasts, id: \.self) {
                    Text($0.name)
                }
            }
            Section("Lunches") {
                ForEach(diary.lunches, id: \.self) {
                    Text($0.name)
                }
            }
            Section("Dinners") {
                ForEach(diary.dinners, id: \.self) {
                    Text($0.name)
                }
            }
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        DiaryView(selection: .constant(nil))
            .environment(preview.diaries[0])
    }
}
