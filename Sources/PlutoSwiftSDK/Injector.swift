import SwiftUI
import WebKit

struct Injector: UIViewRepresentable {
    /// Data to inject
    let manifest: ManifestFile
    let cookies: [HTTPCookie]
    
    /// The communication callback
    /// - Parameter message: String message coming from JS
    let onMessage: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onMessage: onMessage)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // 1) Prepare a WKWebViewConfiguration
        let config = WKWebViewConfiguration()
        
        // 2) Set up our script message handler
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "swiftChannel")
        config.userContentController = userContentController
        
        // 3) Create the WKWebView
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        // 4) Load a trivial HTML so we have a DOM
        let html = "<html><body></body></html>"
        webView.loadHTMLString(html, baseURL: nil)
        
        // 5) Insert cookies
        //    A) Programmatically via `document.cookie = ...` (simplest),
        //       or B) Use WKHTTPCookieStore if you need them to persist.
        cookies.forEach { cookie in
            let jsCookie = """
            document.cookie = "\(cookie.name)=\(cookie.value)";
            """
            let userScript = WKUserScript(source: jsCookie,
                                          injectionTime: .atDocumentStart,
                                          forMainFrameOnly: false)
            userContentController.addUserScript(userScript)
        }
        
        // 6) Inject manifest as JS variable
        if let manifestData = try? JSONEncoder().encode(manifest),
           let manifestJSON = String(data: manifestData, encoding: .utf8) {
            let injectManifestJS = """
            window.__MANIFEST__ = \(manifestJSON);
            """
            let userScript = WKUserScript(source: injectManifestJS,
                                          injectionTime: .atDocumentEnd,
                                          forMainFrameOnly: false)
            userContentController.addUserScript(userScript)
        }
        
        // The webView is not visible, so you might size it to 0x0
        // or place it off-screen in SwiftUI.
        webView.isHidden = true
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op; we’re just injecting once on creation.
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let onMessage: (String) -> Void
        
        init(onMessage: @escaping (String) -> Void) {
            self.onMessage = onMessage
        }
        
        // Handle JS messages: `window.webkit.messageHandlers.swiftChannel.postMessage(...)`
        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "swiftChannel" else { return }
            
            if let bodyStr = message.body as? String {
                onMessage(bodyStr)
            }
        }
        
        // WKNavigationDelegate methods if you need them
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // e.g., confirm load
        }
    }
}
