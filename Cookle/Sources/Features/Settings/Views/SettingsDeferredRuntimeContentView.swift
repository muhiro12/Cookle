import SwiftUI

struct SettingsDeferredRuntimeContentView<Content: View>: View {
    @State private var isRuntimeContentReady = false

    private let content: () -> Content

    var body: some View {
        Group {
            if isRuntimeContentReady {
                content()
            } else {
                loadingView
            }
        }
        .task {
            guard isRuntimeContentReady == false else {
                return
            }

            await Task.yield()
            isRuntimeContentReady = true
        }
    }

    init(
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
    }
}

private extension SettingsDeferredRuntimeContentView {
    var loadingView: some View {
        VStack(spacing: SettingsDeferredRuntimeContentLayout.loadingViewSpacing) {
            ProgressView()
            Text("Loading...")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}
