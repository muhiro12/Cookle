//
//  DiaryFormNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/17.
//

import SwiftData
import SwiftUI

struct DiaryFormNavigationView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Environment(Diary.self) private var diary: Diary?

    @Query(Recipe.descriptor) private var recipes: [Recipe]

    @State private var date = Date.now
    @State private var breakfasts = Set<Recipe>()
    @State private var lunches = Set<Recipe>()
    @State private var dinners = Set<Recipe>()
    @State private var note = ""
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                Section {
                    NavigationLink(DiaryObjectType.breakfast.title,
                                   value: DiaryObjectType.breakfast)
                } footer: {
                    Text(recipes.compactMap {
                        guard breakfasts.contains($0) else {
                            return nil
                        }
                        return $0.name
                    }.joined(separator: ", "))
                }
                Section {
                    NavigationLink(DiaryObjectType.lunch.title,
                                   value: DiaryObjectType.lunch)
                } footer: {
                    Text(recipes.compactMap {
                        guard lunches.contains($0) else {
                            return nil
                        }
                        return $0.name
                    }.joined(separator: ", "))
                }
                Section {
                    NavigationLink(DiaryObjectType.dinner.title,
                                   value: DiaryObjectType.dinner)
                } footer: {
                    Text(recipes.compactMap {
                        guard dinners.contains($0) else {
                            return nil
                        }
                        return $0.name
                    }.joined(separator: ", "))
                }
                Section("Note") {
                    TextField("Note", text: $note, axis: .vertical)
                }
            }
            .navigationDestination(for: DiaryObjectType.self) { type in
                List(
                    recipes.filter {
                        guard !searchText.isEmpty else {
                            return true
                        }
                        return $0.name.lowercased().contains(searchText.lowercased())
                    },
                    id: \.self,
                    selection: {
                        switch type {
                        case .breakfast:
                            $breakfasts

                        case .lunch:
                            $lunches

                        case .dinner:
                            $dinners
                        }
                    }()
                ) { recipe in
                    Text(recipe.name)
                }
                .searchable(text: $searchText)
                .environment(\.editMode, .constant(.active))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(diary != nil ? "Update" : "Add") {
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
                    }
                    .disabled(breakfasts.isEmpty && lunches.isEmpty && dinners.isEmpty)
                }
            }
        }
        .task {
            date = diary?.date ?? .now
            breakfasts = .init(diary?.objects.orEmpty.filter { $0.type == .breakfast }.sorted { $0.order < $1.order }.compactMap { $0.recipe } ?? [])
            lunches = .init(diary?.objects.orEmpty.filter { $0.type == .lunch }.sorted { $0.order < $1.order }.compactMap { $0.recipe } ?? [])
            dinners = .init(diary?.objects.orEmpty.filter { $0.type == .dinner }.sorted { $0.order < $1.order }.compactMap { $0.recipe } ?? [])
            note = diary?.note ?? ""
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    CooklePreview { _ in
        DiaryFormNavigationView()
    }
}
