import UIKit
import WebKit

let ManifestBuilder = """
        class RequestImpl {
          constructor(requestObject, nested) {
            this.data = {};
            this.extra = undefined;

            // We don't want to recursively add the extra object to the extra object
            if (!nested) {
              this.extra = new RequestImpl(requestObject.extra ?? {}, true);
            }
            this.data = requestObject;
          }

          get(key) {
            switch (key) {
              case "method":
                return this.data.method;
              case "url":
                return this.data.url;
              case "headers":
                throw new Error(
                  "To access headers, use manifest.request.getHeader(key)"
                );
              case "body":
                return this.data.body;
              case "vars":
                throw new Error("Vars are inaccessible");
            }
          }

          getHeader(key) {
            return this.data.headers?.[key];
          }

          set(key, value) {
            const dataAsString = JSON.stringify(this.data);
            const expression = new RegExp("<%\\\\s*" + key + "\\\\s*%>", "gi");
            const updatedData = dataAsString.replaceAll(expression, value);
            this.data = JSON.parse(updatedData);

            return this;
          }

          compile() {
            if (this.extra) {
              this.data.extra = this.extra.compile?.();
            }
            return this.data;
          }
        }

        class ResponseImpl {
          constructor(responseObject) {
            this.data = responseObject;
          }

          get(key) {
            switch (key) {
              case "status":
                return this.data.status;
              case "headers":
                throw new Error(
                  "To access headers, use manifest.request.getHeader(key)"
                );
              case "body":
                return this.data.body;
            }
          }

          getHeader(key) {
            return this.data.headers?.[key];
          }

          set(key, value) {
            const dataAsString = JSON.stringify(this.data);
            const expression = new RegExp("<%\\\\s*" + key + "\\\\s*%>", "gi");
            const updatedData = dataAsString.replaceAll(expression, value);
            this.data = JSON.parse(updatedData);

            return this;
          }

          compile() {
            return this.data;
          }
        }

        class ManifestBuilder {
          constructor(manifest = {}) {
            this.debugLogs = [];
            this.manifest = manifest;

            if (!manifest.request) {
              throw new Error("manifest.request object is required");
            }
            if (!manifest.response) {
              throw new Error("manifest.response object is required");
            }

            this.request = new RequestImpl(this.manifest.request);
            this.response = new ResponseImpl(this.manifest.response);
          }

          appendDebugLog(log) {
            this.debugLogs.push(log);
            return this;
          }

          compile() {
            return {
              ...this.manifest,
              debugLogs: this.debugLogs,
              request: this.request.compile(),
              response: this.response.compile(),
            };
          }
        }
        """;

// Internal since it's only used internally
internal class Injector: UIView, WKNavigationDelegate, WKScriptMessageHandler {
    // MARK: - Properties
    private let webView: WKWebView
    private var manifest: ManifestFile
    private var prepareJS: String?
    private var currentCookies: [String: HTTPCookie]
    private var currentDOM: String

    public var onComplete: ((ManifestFile) -> Void)?

    // MARK: - Initialization
    public init(manifest: ManifestFile,
                cookies: [String: HTTPCookie],
                initialDOM: String,
                prepareJS: String? = nil) {
        self.manifest = manifest
        self.currentCookies = cookies
        self.currentDOM = initialDOM
        self.prepareJS = prepareJS

        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        config.userContentController = contentController

        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init(frame: .zero)

        setupWebView(with: contentController)
        reinitializePage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupWebView(with contentController: WKUserContentController) {
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
    }

    // MARK: - Page Management
    private func reinitializePage() {
        let html = generateHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func generateHTML() -> String {
        let script = """
        <script>
            \(ManifestBuilder)
            \(prepareJS ?? "")

            (function() {
                try {
                    const manifestBuilder = new ManifestBuilder(\(try! manifest.toJSONString()));
                    const ctx = {
                        cookies: \(try! currentCookies.toJSONString()),
                        doc: document.body,
                    };

                    const isReady = prepare(ctx, manifestBuilder);

                    window.webkit.messageHandlers.jsToSwift.postMessage({
                        isReady,
                        manifest: JSON.stringify(manifestBuilder.compile()),
                    });
                } catch(e) {
                    window.webkit.messageHandlers.jsToSwift.postMessage({
                        error: e.message
                    });
                }
            })();
        </script>
        """

        return """
        <html>
        <body>
            \(currentDOM)
            \(script)
        </body>
        </html>
        """
    }

    // MARK: - Public Methods
    public func updateData(cookies: [String: HTTPCookie], dom: String) {
        currentCookies = cookies
        currentDOM = dom
        reinitializePage()
    }

    public func close() {
        removeFromSuperview()
    }

    // MARK: - WKScriptMessageHandler
    @objc public func userContentController(_ userContentController: WKUserContentController,
                                          didReceive message: WKScriptMessage) {
        guard message.name == "jsToSwift" else { return }

        if let body = message.body as? [String: Any] {
            handleScriptMessage(body)
        }
    }

    private func handleScriptMessage(_ body: [String: Any]) {
        if let isReady = body["isReady"] as? Bool,
           let manifestString = body["manifest"] as? String,
           isReady,
           let updatedManifest = ManifestParser.parseManifest(from: manifestString) {
            onComplete?(updatedManifest)
        }
    }

    // MARK: - Utilities
    private func escapeForJSString(_ raw: String) -> String {
        return "\"" + raw
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n") + "\""
    }
}
