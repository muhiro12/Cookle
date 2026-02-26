import SwiftUI
import UIKit

struct MigrationTraceLogView: View {
    @State private var logLines = [String]()
    @State private var isCopySucceededMessageVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Reload") {
                    reloadLogs()
                }
                Button("Copy All") {
                    copyLogs()
                }
                .disabled(logLines.isEmpty)
                Button("Clear", role: .destructive) {
                    clearLogs()
                }
                .disabled(logLines.isEmpty)
                Spacer()
            }

            if isCopySucceededMessageVisible {
                Text("Copied logs to clipboard.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if logLines.isEmpty {
                ContentUnavailableView(
                    "No Logs",
                    systemImage: "text.page.slash",
                    description: Text("Migration logs will appear after app launch.")
                )
            } else {
                ScrollView {
                    Text(fullLogText)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }
        .padding()
        .navigationTitle("Migration Logs")
        .task {
            reloadLogs()
        }
    }
}

private extension MigrationTraceLogView {
    var fullLogText: String {
        logLines.joined(separator: "\n")
    }

    func reloadLogs() {
        logLines = MigrationTraceStore.load()
    }

    func copyLogs() {
        UIPasteboard.general.string = fullLogText
        withAnimation {
            isCopySucceededMessageVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopySucceededMessageVisible = false
            }
        }
    }

    func clearLogs() {
        MigrationTraceStore.clear()
        reloadLogs()
    }
}

@available(iOS 18.0, *)
#Preview {
    NavigationStack {
        MigrationTraceLogView()
    }
}
