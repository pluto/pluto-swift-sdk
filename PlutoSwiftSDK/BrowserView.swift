import UIKit
import WebKit

public class BrowserView: UIView {
    private var webView = WKWebView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupWebView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }

    private func setupWebView() {
        webView.frame = self.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(webView)
    }

    public func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
