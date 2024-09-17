import SwiftUI
import SwiftUtilities

struct DebugNavigationSidebarView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.isPresented) private var isPresented

    @AppStorage(.isDebugOn) private var isDebugOn

    @Binding private var content: DebugContent?

    @State private var isAlertPresented = false

    init(selection: Binding<DebugContent?> = .constant(nil)) {
        _content = selection
    }

    var body: some View {
        List(selection: $content) {
            Section {
                Toggle("Debug On", isOn: $isDebugOn)
            } header: {
                Text("AppStorage")
            }
            Section {
                ForEach(DebugContent.allCases, id: \.self) { content in
                    NavigationLink(value: content) {
                        Text(content.rawValue.capitalized)
                    }
                }
            } header: {
                Text("Models")
            }
            Section {
                Button("Create Preview Diary", systemImage: "flask") {
                    isAlertPresented = true
                }
            } header: {
                Text("Manage")
            }
            StoreSection()
            AdvertisementSection(.medium)
            AdvertisementSection(.small)
        }
        .navigationTitle(Text("Debug"))
        .toolbar {
            if isPresented {
                CloseButton()
            }
        }
        .alert("Create Preview Diary", isPresented: $isAlertPresented) {
            Button(role: .destructive) {
                withAnimation {
                    _ = CooklePreviewStore().createPreviewDiary(context)
                }
            } label: {
                Text("Create")
            }
            Button(role: .cancel) {
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("Are you really going to create Preview Diary?")
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            DebugNavigationSidebarView()
        }
    }
}
