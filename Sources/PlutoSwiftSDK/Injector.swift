import UIKit
import WebKit

public class Injector: UIView, WKScriptMessageHandler {
    private let webView: WKWebView
    private var manifest: ManifestFile
    public var onComplete: ((ManifestFile) -> Void)?

    // Keep track of the current cookies + DOM
    private var currentCookies: [HTTPCookie]
    private var currentDOM: String

    public init(manifest: ManifestFile, cookies: [HTTPCookie], initialDOM: String) {
        print("IN")
        self.manifest = manifest
        self.currentCookies = cookies
        self.currentDOM = initialDOM

        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        config.userContentController = contentController

        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init(frame: .zero)

        contentController.add(self, name: "jsToSwift")

        webView.navigationDelegate = self
        webView.isHidden = true
        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Set cookies
        injectCookies(cookies)

        // Load minimal HTML
        let html = """
        <html>
        <body>
        <script>
          // JS can send messages back to Swift:
           window.webkit.messageHandlers.jsToSwift.postMessage({ updatedManifest: {} });
        </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Update data with new cookies + DOM from the BrowserView
    public func updateData(cookies: [HTTPCookie], dom: String) {
        currentCookies = cookies
        currentDOM = dom

        // Re-inject cookies into the WKWebView
        injectCookies(cookies)

        // Optionally, evaluate JS passing the updated DOM
        let escapedDOM = escapeForJSString(dom)
        let js = "window.latestDOM = \(escapedDOM);"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // Called when the injector is done
    public func close() {
        removeFromSuperview()
    }

    // MARK: - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        if message.name == "jsToSwift" {
            print("Message Received: ", message.body)
            // Possibly parse updated manifest from JS
            if let body = message.body as? [String: Any],
               let updatedManifestDict = body["updatedManifest"] as? [String: Any] {
                // decode or transform as needed
                // For brevity, assume we just call onComplete with the existing manifest
//                onComplete?(manifest)
            }
        }
    }

    private func injectCookies(_ cookies: [HTTPCookie]) {
        let store = webView.configuration.websiteDataStore.httpCookieStore
        for cookie in cookies {
            store.setCookie(cookie)
        }
    }

    private func escapeForJSString(_ raw: String) -> String {
        // Minimal escaping example
        return "\"" + raw
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n") + "\""
    }
}

extension Injector: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // You could also inject the initial DOM or manifest here
        let escapedDOM = escapeForJSString(currentDOM)
        let js = "window.latestDOM = \(escapedDOM);"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}
