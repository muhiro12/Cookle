import SwiftUI
import WebKit

struct LicenseView: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        let webView = WKWebView()
        if let url = Bundle.module.url(forResource: "License", withExtension: "html") {
            webView.load(.init(url: url))
        }
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

#Preview {
    LicenseView()
}
