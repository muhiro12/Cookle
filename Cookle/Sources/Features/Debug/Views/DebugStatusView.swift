import MHPlatform
import MHUI
import SwiftData
import SwiftUI

struct DebugStatusView: View {
    private let title: LocalizedStringKey

    @Environment(\.modelContext)
    private var context
    @Environment(MHAppRuntime.self)
    private var appRuntime
    @Environment(\.scenePhase)
    private var scenePhase

    @State private var counts: DiagnosticRecordCounts?
    @State private var didFailToRead = false

    var body: some View {
        List {
            MHContainerContent {
                statusSection
                recordsSection
            }
        }
        .listStyle(.insetGrouped)
        .mhListChrome(.native)
        .navigationTitle(Text(title))
        .task {
            refresh()
        }
        .refreshable {
            refresh()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                refresh()
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var statusSection: some View {
        Section("Status") {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
            LabeledContent("iCloud") {
                Text(context.container.isICloudSyncEnabled ? "On" : "Off")
            }
            LabeledContent("Subscription") {
                switch appRuntime.premiumStatus {
                case .unknown:
                    Text("Unknown")
                case .inactive:
                    Text("Inactive")
                case .active:
                    Text("Active")
                }
            }
        }
    }

    private var recordsSection: some View {
        Section {
            if let counts {
                LabeledContent("Diaries", value: counts.diaries.formatted())
                LabeledContent("DiaryObjects", value: counts.diaryObjects.formatted())
                LabeledContent("Recipes", value: counts.recipes.formatted())
                LabeledContent("Photos", value: counts.photos.formatted())
                LabeledContent("PhotoObjects", value: counts.photoObjects.formatted())
                LabeledContent("Ingredients", value: counts.ingredients.formatted())
                LabeledContent("IngredientObjects", value: counts.ingredientObjects.formatted())
                LabeledContent("Categories", value: counts.categories.formatted())
            } else if didFailToRead {
                Text("Cannot Read Status")
            } else {
                ProgressView()
            }
        } header: {
            Text("Saved Records")
        } footer: {
            Text("Counts show records saved on this device. They do not confirm iCloud sync completion.")
        }
    }

    init(title: LocalizedStringKey = "Status") {
        self.title = title
    }

    private func refresh() {
        do {
            counts = try DiagnosticRecordCounts.read(container: context.container)
            didFailToRead = false
        } catch {
            counts = nil
            didFailToRead = true
        }
    }
}
