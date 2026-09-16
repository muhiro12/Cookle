import CookleLibrary
import Observation
import WebKit

@MainActor
@Observable
final class RecipeWebsiteReader: NSObject, WKNavigationDelegate {
    private struct PendingRead {
        let identifier: UUID
        let continuation: CheckedContinuation<String, any Error>
        let timeout: Task<Void, Never>
    }

    private enum Limits {
        static let timeout: TimeInterval = 30
        static let readTimeoutSeconds = 15
        static let navigations = 10
        static let successfulStatus = 200..<300
        static let responseBytes: Int64 = 3_000_000
    }

    let webView: WKWebView
    private(set) var isReady = false
    private(set) var errorMessage = ""
    private var navigationCount = 0
    private var pendingRead: PendingRead?
    private var navigationIdentifier = UUID()
    private var navigationTimeout: Task<Void, Never>?

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        webView = .init(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
    }

    func load(_ url: URL) {
        stop()
        errorMessage = ""
        isReady = false
        navigationCount = 0
        webView.load(URLRequest(url: url, timeoutInterval: Limits.timeout))
    }

    func stop() {
        navigationIdentifier = UUID()
        navigationTimeout?.cancel()
        navigationTimeout = nil
        isReady = false
        if let pendingRead {
            finishRead(pendingRead.identifier, result: .failure(CancellationError()))
        }
        webView.stopLoading()
    }

    func read() async throws -> (source: RecipeWebsiteSource, url: URL) {
        guard isReady, pendingRead == nil, let url = webView.url,
              RecipeWebsiteImportOperations.websiteURL(from: url.absoluteString) != nil else {
            throw RecipeWebsiteImportError.noContent
        }
        let identifier = UUID()
        let readNavigationIdentifier = navigationIdentifier
        let string = try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await evaluatePage(identifier)
        } onCancel: {
            Task { @MainActor in
                self.finishRead(identifier, result: .failure(CancellationError()))
            }
        }
        try Task.checkCancellation()
        guard isReady, readNavigationIdentifier == navigationIdentifier, url == webView.url,
              let data = string.data(using: .utf8),
              let content = try? JSONDecoder().decode(PageContent.self, from: data) else {
            throw RecipeWebsiteImportError.noContent
        }
        return (
            try RecipeWebsiteImportOperations.source(
                structuredData: content.structuredData,
                visibleText: content.visibleText,
                knownIngredients: content.ingredients.map { ingredient in
                    .init(ingredient: ingredient.ingredient, amount: ingredient.amount)
                },
                equipment: content.equipment,
                knownSteps: content.steps,
                sourceNotes: content.notes,
                servingText: content.servingText
            ),
            url
        )
    }

    private func evaluatePage(_ identifier: UUID) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let timeout = Task { @MainActor in
                do {
                    try await Task.sleep(for: .seconds(Limits.readTimeoutSeconds))
                    finishRead(identifier, result: .failure(RecipeWebsiteImportError.noContent))
                } catch {
                    // Completion or dismissal cancelled the deadline.
                }
            }
            pendingRead = .init(identifier: identifier, continuation: continuation, timeout: timeout)
            webView.evaluateJavaScript(Self.extractionScript, in: nil, in: .defaultClient) { [weak self] result in
                let text = result.flatMap { value -> Result<String, any Error> in
                    guard let text = value as? String else {
                        return .failure(RecipeWebsiteImportError.noContent)
                    }
                    return .success(text)
                }
                self?.finishRead(identifier, result: text)
            }
        }
    }

    private func finishRead(_ identifier: UUID, result: Result<String, any Error>) {
        guard let pendingRead, pendingRead.identifier == identifier else {
            return
        }
        self.pendingRead = nil
        pendingRead.timeout.cancel()
        pendingRead.continuation.resume(with: result)
    }

    func webView(_: WKWebView, didFinish _: WKNavigation?) {
        navigationTimeout?.cancel()
        navigationTimeout = nil
        isReady = errorMessage.isEmpty
    }

    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation?) {
        isReady = false
        errorMessage = ""
        navigationIdentifier = UUID()
        if let pendingRead {
            finishRead(pendingRead.identifier, result: .failure(CancellationError()))
        }
        navigationTimeout?.cancel()
        let identifier = navigationIdentifier
        navigationTimeout = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(Limits.timeout))
                guard let self, identifier == navigationIdentifier else {
                    return
                }
                stop()
                webViewWebContentProcessDidTerminate(webView)
            } catch {
                // Completion, replacement, or dismissal cancelled this navigation's deadline.
            }
        }
    }

    func webView(_: WKWebView, didFail _: WKNavigation?, withError error: any Error) {
        show(error)
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation?, withError error: any Error) {
        show(error)
    }

    func webViewWebContentProcessDidTerminate(_: WKWebView) {
        navigationTimeout?.cancel()
        navigationTimeout = nil
        isReady = false
        errorMessage = String(localized: "The page could not be loaded. Try again or paste the recipe text.")
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @MainActor (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url,
              RecipeWebsiteImportOperations.websiteURL(from: url.absoluteString) != nil else {
            decisionHandler(.cancel)
            return
        }
        if navigationAction.targetFrame?.isMainFrame == true {
            if navigationAction.navigationType == .linkActivated {
                navigationCount = 0
            }
            navigationCount += 1
            guard navigationCount <= Limits.navigations else {
                webViewWebContentProcessDidTerminate(webView)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @MainActor (WKNavigationResponsePolicy) -> Void
    ) {
        guard navigationResponse.isForMainFrame else {
            decisionHandler(.allow)
            return
        }
        let response = navigationResponse.response
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard Limits.successfulStatus.contains(status),
              ["text/html", "application/xhtml+xml"].contains(response.mimeType),
              response.expectedContentLength <= Limits.responseBytes else {
            webViewWebContentProcessDidTerminate(webView)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

private extension RecipeWebsiteReader {
    struct PageIngredient: Decodable {
        let ingredient: String
        let amount: String
    }

    struct PageContent: Decodable {
        let structuredData: [String]
        let visibleText: String
        let ingredients: [PageIngredient]
        let equipment: [String]
        let steps: [String]
        let notes: [String]
        let servingText: String
    }

    // Use an isolated JavaScript world. Page text is untrusted input, never executable instructions.
    static let extractionScript = #"""
        (() => {
        const structuredData = [];
        let size = 0;
        for (const script of document.querySelectorAll('script[type="application/ld+json"]')) {
        size += script.textContent.length;
        if (size > 1000000) throw new Error('Page data is too large');
        structuredData.push(script.textContent);
        }
        const root = document.querySelector('main, article, [role="main"]') || document.body;
        if (!root) return JSON.stringify({structuredData, visibleText: '',
        ingredients: [], equipment: [], steps: [], notes: [], servingText: ''});
        const lines = [];
        const headerLines = [];
        let length = 0;
        const excluded = 'script,style,nav,header,footer,iframe,button,select,textarea,svg,'
        + '[hidden],[aria-hidden="true"],[role="button"],a:not([href]),a[href^="javascript:"]';
        const ingredientsHeading = [...root.querySelectorAll('h1,h2,h3,h4,h5,h6')].find(h =>
        /^(材料|食材|ingredients|ingredientes|ingrédients)/i.test(h.innerText));
        const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
        while (walker.nextNode()) {
        const node = walker.currentNode;
        const parent = node.parentElement;
        if (!parent || parent.closest(excluded) || parent.getClientRects().length === 0) continue;
        const style = getComputedStyle(parent);
        if (style.visibility === 'hidden' || style.display === 'none') continue;
        const text = node.textContent.trim();
        if (!text) continue;
        lines.push(text);
        if (ingredientsHeading && (ingredientsHeading.contains(node)
        || (ingredientsHeading.compareDocumentPosition(node) & Node.DOCUMENT_POSITION_PRECEDING))) {
        headerLines.push(text);
        }
        length += text.length + 1;
        if (length > 16000) break;
        }
        const headings = [...root.querySelectorAll('h1,h2,h3,h4,h5,h6')];

        const stepsHeading = headings.find(h =>
        (!ingredientsHeading || (ingredientsHeading.compareDocumentPosition(h) & Node.DOCUMENT_POSITION_FOLLOWING))
        && /^(作りかた|作り方|手順|steps|directions|instructions|method|préparation|preparación)/i.test(h.innerText));
        const headerText = headerLines.join('\n');
        const countPattern = /\d+(?:\s*[〜～~-]\s*\d+)?/.source;
        const servingPattern = new RegExp(String.raw`(?:^|\n)(?:材料[：:]\s*)?(${countPattern}`
        + String.raw`\s*(?:人分|人前|servings?|people|persons?))(?:$|\n)`, 'i');
        const servesPattern = new RegExp(String.raw`(?:^|\n)(serves\s+${countPattern})(?:$|\n)`, 'i');
        const servingMatch = headerText.match(servingPattern) || headerText.match(servesPattern);
        const servingText = (servingMatch?.[1] || '').replace(/\s+/g, ' ');
        const ingredients = [];
        const notes = [];
        const steps = [];
        const visible = element => !element.closest(excluded)
        && element.getClientRects().length > 0 && getComputedStyle(element).visibility !== 'hidden';
        const between = (element, start, end) => visible(element)
        && (start.compareDocumentPosition(element) & Node.DOCUMENT_POSITION_FOLLOWING)
        && (!end || (end.compareDocumentPosition(element) & Node.DOCUMENT_POSITION_PRECEDING));
        const readText = element => {
        // Keep inline references together, but retain block boundaries and line breaks.
        const visit = node => {
        if (node.nodeType === Node.TEXT_NODE) return node.textContent;
        if (node.nodeType !== Node.ELEMENT_NODE || !visible(node)) return '';
        if (node.tagName === 'BR') return '\n';
        const text = [...node.childNodes].map(visit).join('');
        return getComputedStyle(node).display.startsWith('inline') ? text : '\n' + text + '\n';
        };
        return visit(element).replace(/[ \t]+/g, ' ').replace(/ *\n */g, '\n')
        .replace(/\n{3,}/g, '\n\n').trim();
        };
        if (ingredientsHeading && stepsHeading) {
        for (const row of root.querySelectorAll('dl')) {
        if (!(ingredientsHeading.compareDocumentPosition(row) & Node.DOCUMENT_POSITION_FOLLOWING)
        || !(stepsHeading.compareDocumentPosition(row) & Node.DOCUMENT_POSITION_PRECEDING)) continue;
        const name = row.querySelector('dt')?.innerText.trim();
        const amount = row.querySelector('dd')?.innerText.trim();
        const siblings = [...row.parentElement.children];
        const firstRow = siblings.findIndex(element => element.tagName === 'DL');
        const group = siblings.slice(0, firstRow).map(element => element.innerText.trim())
        .filter(text => /^[A-ZＡ-Ｚ★☆◎●○◯①-⑳]$/.test(text)).join('');
        const ingredient = group ? `[${group}] ${name}` : name;
        if (visible(row) && name && amount) ingredients.push({ingredient, amount});
        else if (visible(row) && name && amount === '') notes.push(name);
        }
        }
        for (const paragraph of root.querySelectorAll('p')) {
        if (ingredientsHeading && stepsHeading && between(paragraph, ingredientsHeading, stepsHeading)
        && !paragraph.closest('dl') && !paragraph.parentElement.closest('p')) {
        const text = readText(paragraph);
        if (text) notes.push(text);
        }
        }
        if (stepsHeading) {
        const end = headings.find(h => Number(h.tagName.slice(1)) <= Number(stepsHeading.tagName.slice(1))
        && (stepsHeading.compareDocumentPosition(h) & Node.DOCUMENT_POSITION_FOLLOWING));
        const lists = [...root.querySelectorAll('ol')].filter(list =>
        between(list, stepsHeading, end) && !list.parentElement.closest('ol'));
        // Multiple independent lists are ambiguous; leave their interpretation to the editable input.
        if (lists.length === 1) {
        const rows = [...lists[0].children].filter(row => row.tagName === 'LI' && visible(row));
        const marker = row => row.firstElementChild?.tagName === 'DIV'
        ? readText(row.firstElementChild) : '';
        const explicitlyNumbered = rows.length >= 2 && marker(rows[0]) === '1' && marker(rows[1]) === '2';
        for (const row of rows) {
        const number = marker(row);
        let text = readText(row);
        if (explicitlyNumbered && /^\d+$/.test(number)) {
        text = text.replace(/^\d+\s*\n/, '').trim();
        steps.push(text);
        } else if (text) {
        (explicitlyNumbered ? notes : steps).push(text);
        }
        }
        }
        for (const paragraph of root.querySelectorAll('p')) {
        if (between(paragraph, stepsHeading, end) && !paragraph.closest('ol,ul')
        && !paragraph.parentElement.closest('p')) {
        const text = readText(paragraph);
        if (text) notes.push(text);
        }
        }
        }
        const equipment = [...document.querySelectorAll('button')]
        .map(button => button.innerText.trim())
        .filter(text => /^[A-Z]{1,5}-[A-Z0-9-]{2,20}$/.test(text));
        const visibleText = [...equipment, ...lines].join('\n');
        return JSON.stringify({structuredData, ingredients, equipment, visibleText, steps, notes, servingText});
        })()
    """#

    func show(_ error: any Error) {
        guard (error as NSError).code != NSURLErrorCancelled else {
            return
        }
        navigationTimeout?.cancel()
        navigationTimeout = nil
        isReady = false
        errorMessage = String(localized: "The page could not be loaded. Try again or paste the recipe text.")
    }
}
