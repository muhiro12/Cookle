import SwiftUI

struct DebugSidebarView: View {
    @AppStorage(.isICloudOn) private var isICloudOn
    @AppStorage(.isDebugOn) private var isDebugOn

    @Binding private var selection: DebugContent?

    init(selection: Binding<DebugContent?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Section("Models") {
                ForEach(DebugContent.allCases, id: \.self) { content in
                    switch content {
                    case .diary:
                        Text("Diaries")
                    case .diaryObject:
                        Text("DiaryObjects")
                    case .recipe:
                        Text("Recipes")
                    case .ingredient:
                        Text("Ingredients")
                    case .ingredientObject:
                        Text("IngredientObjects")
                    case .category:
                        Text("Categories")
                    }
                }
            }
            Section("Settings") {
                Toggle("iCloud On", isOn: $isICloudOn)
                Toggle("Debug On", isOn: $isDebugOn)
            }
        }
    }
}

#Preview {
    DebugSidebarView(selection: .constant(nil))
}
