import SwiftUI
import WebKit

struct LoginWebView: UIViewRepresentable {
    let url: URL
    let onTokenReceived: (String) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Improve cookie handling for OAuth
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: LoginWebView

        init(_ parent: LoginWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // Check if the URL is our backend callback redirect
            if let url = navigationAction.request.url {
                print("Navigating to: \(url.absoluteString)")
                
                // The backend redirects to /login/callback?accessToken=...
                if url.path == "/login/callback" {
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                       let accessToken = components.queryItems?.first(where: { $0.name == "accessToken" })?.value {
                        
                        print("Intercepted Access Token successfully")
                        parent.onTokenReceived(accessToken)
                        decisionHandler(.cancel) // Stop loading a blank page
                        return
                    }
                }
            }
            
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView failed provisional navigation: \(error.localizedDescription)")
            // If the error is network related, maybe the backend is not running or unreachable
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView failed navigation: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView finished loading: \(webView.url?.absoluteString ?? "unknown")")
        }
    }
}
