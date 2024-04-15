//
//  DiaryView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI

struct DiaryView: View {
    @Environment(Diary.self) private var diary

    var body: some View {
        List {
            Section("Date") {
                Text(diary.date.description)
            }
            Section("Breakfasts") {
                ForEach(diary.breakfasts) {
                    Text($0.name)
                }
            }
            Section("Lunches") {
                ForEach(diary.lunches) {
                    Text($0.name)
                }
            }
            Section("Dinners") {
                ForEach(diary.dinners) {
                    Text($0.name)
                }
            }
        }
    }
}

#Preview {
    DiaryView()
}
