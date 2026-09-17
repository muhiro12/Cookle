//
//  DiaryFormView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/17.
//

import MHUI
import SwiftData
import SwiftUI

struct DiaryFormView: View {
    @State private var model: DiaryFormModel
    @State private var isDiscardChangesConfirmationPresented = false
    @State private var isRestoreDraftConfirmationPresented = false

    @Environment(\.modelContext)
    private var context
    @Environment(\.dismiss)
    private var dismiss
    @Environment(DiaryActionService.self)
    private var diaryActionService

    @Environment(Diary.self)
    private var diary: Diary?

    private let prefill: DiaryFormPrefill?

    var body: some View {
        @Bindable var model = model

        Form {
            dateSection
            mealSection(type: .breakfast, recipes: $model.breakfasts)
            mealSection(type: .lunch, recipes: $model.lunches)
            mealSection(type: .dinner, recipes: $model.dinners)
            noteSection
        }
        .scrollDismissesKeyboard(.immediately)
        .mhFormChrome()
        .disabled(model.isSaving)
        .navigationDestination(for: DiaryObjectType.self) { type in
            destinationView(for: type)
        }
        .navigationTitle(Text("Diary"))
        .alert(
            Text("Cannot Save Diary"),
            isPresented: isErrorPresentedBinding
        ) {
            Button("OK", role: .cancel) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .toolbar {
            toolbarItems
        }
        .interactiveDismissDisabled()
        .confirmationDialog(
            Text("Restore Draft"),
            isPresented: $isRestoreDraftConfirmationPresented
        ) {
            Button("Restore Draft", role: .destructive) {
                model.restoreSnapshot(
                    context: context
                )
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text("Replace the current form input with the saved draft?")
        }
        .task {
            model.applyInitialValues(
                diary: diary,
                prefill: prefill
            )
            model.activateSnapshotPersistence(
                diary: diary
            )
        }
    }

    var dateSection: some View {
        @Bindable var model = model

        return Section {
            DatePicker("Date", selection: $model.date, displayedComponents: .date)
                .datePickerStyle(.graphical)
        }
    }

    var noteSection: some View {
        @Bindable var model = model

        return Section {
            TextField(
                "Note",
                text: $model.note,
                prompt: Text("Classic spaghetti carbonara and warm beef stew for a comforting end to the day."),
                axis: .vertical
            )
            .accessibilityValue(
                model.note.isEmpty ? Text(verbatim: "") : Text(verbatim: model.note)
            )
        } header: {
            Text("Note")
        }
    }

    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(action: cancelForm) {
                Text("Cancel")
            }
            .disabled(model.isSaving)
            .alert(
                Text("Discard Changes?"),
                isPresented: $isDiscardChangesConfirmationPresented
            ) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {
                    // Dismisses the alert.
                }
            } message: {
                Text("You will lose any unsaved changes.")
            }
        }
        if model.restorePolicy.isRestoreAvailable {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Restore Draft") {
                    restoreDraft()
                }
                .disabled(model.isSaving)
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                Task {
                    let shouldDismiss = await model.save(
                        context: context,
                        diary: diary,
                        diaryActionService: diaryActionService
                    )
                    if shouldDismiss {
                        dismiss()
                    }
                }
            } label: {
                Text(diary != nil ? "Update" : "Add")
            }
            .disabled(model.isSaving || model.canSave == false)
        }
    }

    init(
        prefill: DiaryFormPrefill? = nil,
        persistsDraft: Bool = true
    ) {
        self.prefill = prefill
        _model = .init(initialValue: DiaryFormModel(persistsSnapshot: persistsDraft))
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    DiaryFormNavigationView()
}

private extension DiaryFormView {
    var isErrorPresentedBinding: Binding<Bool> {
        .init(
            get: {
                model.errorMessage != nil
            },
            set: { isPresented in
                if isPresented == false {
                    model.errorMessage = nil
                }
            }
        )
    }

    func mealSection(
        type: DiaryObjectType,
        recipes: Binding<Set<Recipe>>
    ) -> some View {
        Section {
            NavigationLink(value: type) {
                DiaryMealSelectionLabel(
                    type: type,
                    recipeNames: recipes.wrappedValue.map(\.name).sorted { firstName, secondName in
                        firstName.localizedStandardCompare(secondName) == .orderedAscending
                    }
                )
            }
        }
    }

    @ViewBuilder
    func destinationView(for type: DiaryObjectType) -> some View {
        switch type {
        case .breakfast:
            DiaryFormRecipeListView(
                selection: Binding(
                    get: {
                        model.breakfasts
                    },
                    set: { newValue in
                        model.breakfasts = newValue
                    }
                ),
                type: type
            )
        case .lunch:
            DiaryFormRecipeListView(
                selection: Binding(
                    get: {
                        model.lunches
                    },
                    set: { newValue in
                        model.lunches = newValue
                    }
                ),
                type: type
            )
        case .dinner:
            DiaryFormRecipeListView(
                selection: Binding(
                    get: {
                        model.dinners
                    },
                    set: { newValue in
                        model.dinners = newValue
                    }
                ),
                type: type
            )
        }
    }

    func restoreDraft() {
        guard model.isSaving == false else {
            return
        }

        if model.restorePolicy.requiresOverwriteConfirmation {
            isRestoreDraftConfirmationPresented = true
            return
        }

        model.restoreSnapshot(
            context: context
        )
    }

    func cancelForm() {
        guard model.isSaving == false else {
            return
        }
        guard model.hasUnsavedChanges else {
            dismiss()
            return
        }

        isDiscardChangesConfirmationPresented = true
    }
}
