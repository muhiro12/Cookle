//
//  DiaryFormView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/17.
//

import SwiftData
import SwiftUI

struct DiaryFormView: View {
    @Environment(\.modelContext)
    private var context
    @Environment(\.dismiss)
    private var dismiss
    @Environment(DiaryActionService.self)
    private var diaryActionService

    @Environment(Diary.self)
    private var diary: Diary?

    @State private var date = Date.now
    @State private var breakfasts = Set<Recipe>()
    @State private var lunches = Set<Recipe>()
    @State private var dinners = Set<Recipe>()
    @State private var note = ""

    var body: some View {
        Form {
            dateSection
            mealSection(type: .breakfast, recipes: breakfasts)
            mealSection(type: .lunch, recipes: lunches)
            mealSection(type: .dinner, recipes: dinners)
            noteSection
        }
        .navigationDestination(for: DiaryObjectType.self) { type in
            destinationView(for: type)
        }
        .navigationTitle(Text("Diary"))
        .toolbar {
            toolbarItems
        }
        .interactiveDismissDisabled()
        .task {
            applyInitialValues()
        }
    }

    var dateSection: some View {
        Section {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
        }
    }

    var noteSection: some View {
        Section {
            TextField(text: $note, axis: .vertical) {
                Text("Classic spaghetti carbonara and warm beef stew for a comforting end to the day.")
            }
        } header: {
            Text("Note")
        }
    }

    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                Task {
                    await saveDiary()
                }
            } label: {
                Text(diary != nil ? "Update" : "Add")
            }
            .disabled(breakfasts.isEmpty && lunches.isEmpty && dinners.isEmpty)
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    DiaryFormNavigationView()
}

private extension DiaryFormView {
    var formInput: DiaryActionService.FormInput {
        .init(
            breakfasts: .init(breakfasts),
            lunches: .init(lunches),
            dinners: .init(dinners),
            note: note
        )
    }

    func mealSection(
        type: DiaryObjectType,
        recipes: Set<Recipe>
    ) -> some View {
        Section {
            NavigationLink(value: type) {
                Text(type.title)
            }
        } footer: {
            Text(recipes.map(\.name).joined(separator: ", "))
        }
    }

    @ViewBuilder
    func destinationView(for type: DiaryObjectType) -> some View {
        switch type {
        case .breakfast:
            DiaryFormRecipeListView(selection: $breakfasts, type: type)
        case .lunch:
            DiaryFormRecipeListView(selection: $lunches, type: type)
        case .dinner:
            DiaryFormRecipeListView(selection: $dinners, type: type)
        }
    }

    @MainActor
    func saveDiary() async {
        if let diary {
            await diaryActionService.update(
                context: context,
                diary: diary,
                date: date,
                input: formInput
            )
        } else {
            _ = await diaryActionService.create(
                context: context,
                date: date,
                input: formInput
            )
        }
        dismiss()
    }

    func applyInitialValues() {
        date = diary?.date ?? .now
        breakfasts = recipes(for: .breakfast)
        lunches = recipes(for: .lunch)
        dinners = recipes(for: .dinner)
        note = diary?.note ?? ""
    }

    func recipes(for type: DiaryObjectType) -> Set<Recipe> {
        let recipes = diary?.objects.orEmpty
            .filter { object in
                object.type == type
            }
            .sorted()
            .compactMap(\.recipe) ?? []
        return .init(recipes)
    }
}
