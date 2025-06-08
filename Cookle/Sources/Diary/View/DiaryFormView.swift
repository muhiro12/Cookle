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
                            diary.update(
                                date: date,
                                objects: zip(Array(breakfasts).indices, breakfasts).map { index, element in
                                    .create(context: context, recipe: element, type: .breakfast, order: index + 1)
                                } + zip(Array(lunches).indices, lunches).map { index, element in
                                    .create(context: context, recipe: element, type: .lunch, order: index + 1)
                                } + zip(Array(dinners).indices, dinners).map { index, element in
                                    .create(context: context, recipe: element, type: .dinner, order: index + 1)
                                },
                                note: note
                            )
                        } else {
                            _ = Diary.create(
                                context: context,
                                date: date,
                                objects: zip(Array(breakfasts).indices, breakfasts).map { index, element in
                                    .create(context: context, recipe: element, type: .breakfast, order: index + 1)
                                } + zip(Array(lunches).indices, lunches).map { index, element in
                                    .create(context: context, recipe: element, type: .lunch, order: index + 1)
                                } + zip(Array(dinners).indices, dinners).map { index, element in
                                    .create(context: context, recipe: element, type: .dinner, order: index + 1)
                                },
                                note: note
                            )
                        }
                        dismiss()
                    } label: {
                        Text(diary != nil ? "Update" : "Add")
                    }
                    .disabled(breakfasts.isEmpty && lunches.isEmpty && dinners.isEmpty)
                }
            }
        }
        .interactiveDismissDisabled()
        .task {
            date = diary?.date ?? .now
            breakfasts = .init(diary?.objects.orEmpty.filter { $0.type == .breakfast }.sorted().compactMap(\.recipe) ?? [])
            lunches = .init(diary?.objects.orEmpty.filter { $0.type == .lunch }.sorted().compactMap(\.recipe) ?? [])
            dinners = .init(diary?.objects.orEmpty.filter { $0.type == .dinner }.sorted().compactMap(\.recipe) ?? [])
            note = diary?.note ?? ""
        }
    }
}

#Preview {
    CooklePreview { _ in
        DiaryFormNavigationView()
    }
}
