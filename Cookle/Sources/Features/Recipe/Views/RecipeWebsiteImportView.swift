import CookleLibrary
import SwiftUI
import WebKit

struct RecipeWebsiteImportView: View {
    private struct WebsiteView: UIViewRepresentable {
        let webView: WKWebView

        func makeUIView(context _: Context) -> WKWebView {
            webView
        }

        func updateUIView(_: WKWebView, context _: Context) {
            // The reader owns navigation.
        }
    }

    @Environment(\.dismiss)
    private var dismiss
    @State private var reader: RecipeWebsiteReader?
    @State private var address = ""
    @State private var isReading = false
    @State private var errorMessage = ""
    @State private var readTask: Task<Void, Never>?

    let onImport: (RecipeWebsiteSource, URL) -> Void

    var body: some View {
        NavigationStack {
            pageContent
                .navigationTitle("Import from Website")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarItems }
                .overlay {
                    if isReading {
                        ProgressView()
                    }
                }
                .alert("Cannot Import Recipe", isPresented: .init(
                    get: { !errorMessage.isEmpty },
                    set: { if !$0 { errorMessage = "" } }
                )) {
                    Button("OK", role: .cancel) { errorMessage = "" }
                } message: {
                    Text(errorMessage)
                }
                .onDisappear {
                    readTask?.cancel()
                    reader?.stop()
                }
        }
    }

    @ToolbarContentBuilder private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                readTask?.cancel()
                dismiss()
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Use Recipe Text", action: readPage)
                .disabled(reader?.isReady != true || isReading)
        }
    }

    private var pageContent: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Recipe URL", text: $address)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit(openPage)
                Button("Open", action: openPage)
                    .disabled(RecipeWebsiteImportOperations.websiteURL(from: address) == nil)
            }
            .padding()
            .disabled(isReading)
            Divider()
            if let reader {
                WebsiteView(webView: reader.webView)
                    .disabled(isReading)
            } else {
                ContentUnavailableView {
                    Label("Recipe URL", systemImage: "link")
                } description: {
                    Text("Open a recipe page, then use its text to create your own recipe.")
                }
            }
            if let reader, !reader.errorMessage.isEmpty {
                Text(reader.errorMessage)
                    .font(.callout)
                    .padding()
            }
        }
    }

    private func openPage() {
        guard !isReading, let url = RecipeWebsiteImportOperations.websiteURL(from: address) else {
            return
        }
        if reader == nil {
            reader = .init()
        }
        reader?.load(url)
    }

    private func readPage() {
        guard let reader else {
            return
        }
        isReading = true
        readTask = Task { @MainActor in
            defer { isReading = false }
            do {
                let content = try await reader.read()
                try Task.checkCancellation()
                onImport(content.source, content.url)
                dismiss()
            } catch is CancellationError {
                // Dismissal must never update the underlying recipe text.
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                switch error as? RecipeWebsiteImportError {
                case .multipleRecipes:
                    errorMessage = String(localized: "Open a page for a single recipe, or paste the recipe text.")
                case .contentTooLarge:
                    errorMessage = String(localized: "This page is too long. Copy and paste only the recipe text.")
                default:
                    errorMessage = String(localized: "The recipe text could not be read. Copy and paste it instead.")
                }
            }
        }
    }
}

#Preview {
    RecipeWebsiteImportView { _, _ in
        // Preview only.
    }
}
