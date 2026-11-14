#if DEBUG
import MHPlatform
import MHUI
import SwiftData
import SwiftUI
import TipKit

struct DebugSidebarView: View {
    @Environment(\.modelContext)
    private var context
    @Environment(\.isPresented)
    private var isPresented
    @Environment(CookleTipController.self)
    private var tipController

    @Binding private var content: DebugContent?

    @State private var errorMessage: String?
    @State private var isCreatingPreviewDiaries = false
    @State private var isAlertPresented = false

    var body: some View {
        sidebarList
            .cookleTopLevelNavigationChrome("Debug")
            .toolbar {
                ToolbarItem {
                    if isPresented {
                        CloseButton()
                    }
                }
            }
            .confirmationDialog(
                Text("Create Preview Diaries"),
                isPresented: $isAlertPresented
            ) {
                Button(role: .destructive) {
                    guard !isCreatingPreviewDiaries else {
                        return
                    }
                    createPreviewDiaries()
                } label: {
                    Text("Create")
                }
                .disabled(isCreatingPreviewDiaries)
                Button(role: .cancel) {
                    // Dismisses the confirmation dialog.
                } label: {
                    Text("Cancel")
                }
            } message: {
                Text("Samples can only be added to an empty development store.")
            }
            .alert(Text("Cannot Add Samples"), isPresented: .init(
                get: {
                    errorMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        errorMessage = nil
                    }
                }
            )) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
    }

    var sidebarList: some View {
        List {
            MHContainerContent {
                diagnosticsSection
                manageSection
                tipKitSection
                previewSection
                modelSection
            }
        }
        .mhListChrome(.native)
    }

    var manageSection: some View {
        Section {
            Button("Create Preview Diaries", systemImage: "flask") {
                isAlertPresented = true
            }
            .disabled(isCreatingPreviewDiaries || !CookleDevelopmentStore.allowsMutations(context.container))
        } header: {
            Text("Manage")
        }
    }

    var diagnosticsSection: some View {
        Section {
            ForEach(diagnosticDestinations, id: \.title) { destination in
                sidebarButton(
                    title: destination.title,
                    content: destination.content
                )
            }
        } header: {
            Text("Diagnostics")
        }
    }

    var tipKitSection: some View {
        Section("TipKit") {
            Button("Reset Tips") {
                do {
                    try tipController.resetTips()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            Button("Show All Tips For Testing") {
                Tips.showAllTipsForTesting()
            }
            Button("Hide All Tips For Testing") {
                Tips.hideAllTipsForTesting()
            }
        }
    }

    var previewSection: some View {
        Section {
            Button {
                content = .preview
            } label: {
                Text("Previews")
                    .cookleButtonRowContent()
            }
            .buttonStyle(.plain)
        } header: {
            Text("Preview")
        }
    }

    var modelSection: some View {
        Section {
            ForEach(modelDestinations, id: \.title) { destination in
                sidebarButton(
                    title: destination.title,
                    content: destination.content
                )
            }
        } header: {
            Text("Model")
        }
    }

    var modelDestinations: [(title: String, content: DebugContent)] {
        [
            ("Diaries", .diary),
            ("DiaryObjects", .diaryObject),
            ("Recipes", .recipe),
            ("Photos", .photo),
            ("PhotoObjects", .photoObject),
            ("Ingredients", .ingredient),
            ("IngredientObjects", .ingredientObject),
            ("Categories", .category)
        ]
    }

    var diagnosticDestinations: [(title: String, content: DebugContent)] {
        [
            ("Status", .status),
            ("Logs", .logs)
        ]
    }

    init(selection: Binding<DebugContent?> = .constant(nil)) {
        _content = selection
    }

    @MainActor
    private func createPreviewDiaries() {
        isCreatingPreviewDiaries = true
        defer {
            isCreatingPreviewDiaries = false
        }

        do {
            try CookleDevelopmentStore.insertSamples(context: context)
        } catch DevelopmentSampleOperations.SampleError.nonemptyStore {
            errorMessage = String(localized: "Samples can only be added to an empty development store.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sidebarButton(
        title: String,
        content: DebugContent
    ) -> some View {
        Button {
            self.content = content
        } label: {
            Text(LocalizedStringKey(title))
                .cookleButtonRowContent()
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        DebugSidebarView()
    }
}

#endif
