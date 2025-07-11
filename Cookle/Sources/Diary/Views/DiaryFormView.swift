//
//  DiaryFormView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/17.
//

import SwiftData
import SwiftUI

struct DiaryFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Environment(Diary.self) private var diary: Diary?

    @State private var date = Date.now
    @State private var breakfasts = Set<Recipe>()
    @State private var lunches = Set<Recipe>()
    @State private var dinners = Set<Recipe>()
    @State private var note = ""

    var body: some View {
        Form {
            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
            Section {
                NavigationLink(value: DiaryObjectType.breakfast) {
                    Text(DiaryObjectType.breakfast.title)
                }
            } footer: {
                Text(breakfasts.map(\.name).joined(separator: ", "))
            }
            Section {
                NavigationLink(value: DiaryObjectType.lunch) {
                    Text(DiaryObjectType.lunch.title)
                }
            } footer: {
                Text(lunches.map(\.name).joined(separator: ", "))
            }
            Section {
                NavigationLink(value: DiaryObjectType.dinner) {
                    Text(DiaryObjectType.dinner.title)
                }
            } footer: {
                Text(dinners.map(\.name).joined(separator: ", "))
            }
            Section {
                TextField(text: $note, axis: .vertical) {
                    Text("Classic spaghetti carbonara and warm beef stew for a comforting end to the day.")
                }
            } header: {
                Text("Note")
            }
        }
        .navigationDestination(for: DiaryObjectType.self) { type in
            switch type {
            case .breakfast:
                DiaryFormRecipeListView(selection: $breakfasts, type: type)
            case .lunch:
                DiaryFormRecipeListView(selection: $lunches, type: type)
            case .dinner:
                DiaryFormRecipeListView(selection: $dinners, type: type)
            }
        }
        .navigationTitle(Text("Diary"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    if let diary {
                        UpdateDiaryIntent.perform(
                            (
                                context: context,
                                diary: diary,
                                date: date,
                                breakfasts: recipes(from: breakfasts),
                                lunches: recipes(from: lunches),
                                dinners: recipes(from: dinners),
                                note: note
                            )
                        )
                    } else {
                        _ = CreateDiaryIntent.perform(
                            (
                                context: context,
                                date: date,
                                breakfasts: recipes(from: breakfasts),
                                lunches: recipes(from: lunches),
                                dinners: recipes(from: dinners),
                                note: note
                            )
                        )
                    }
                    dismiss()
                } label: {
                    Text(diary != nil ? "Update" : "Add")
                }
                .disabled(breakfasts.isEmpty && lunches.isEmpty && dinners.isEmpty)
            }
        }
        .interactiveDismissDisabled()
        .task {
            date = diary?.date ?? .now
            breakfasts = recipeEntities(from: diary?.objects.orEmpty.filter {
                $0.type == .breakfast
            }.sorted().compactMap(\.recipe) ?? [])
            lunches = recipeEntities(from: diary?.objects.orEmpty.filter {
                $0.type == .lunch
            }.sorted().compactMap(\.recipe) ?? [])
            dinners = recipeEntities(from: diary?.objects.orEmpty.filter {
                $0.type == .dinner
            }.sorted().compactMap(\.recipe) ?? [])
            note = diary?.note ?? ""
        }
    }
}

private extension DiaryFormView {
    func recipes(from models: Set<Recipe>) -> [Recipe] {
        Array(models)
    }

    func recipeEntities(from models: [Recipe]) -> Set<Recipe> {
        Set(models)
    }
}

#Preview {
    CooklePreview { _ in
        DiaryFormNavigationView()
    }
}
