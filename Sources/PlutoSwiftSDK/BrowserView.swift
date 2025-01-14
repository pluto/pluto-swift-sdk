import UIKit
import WebKit

public class BrowserView: UIView {
    private var webView = WKWebView()
    private var manifest: ManifestFile?

    // Closure to handle when the browser is closed
    public var onClose: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .systemBackground

        // Setup WebView
        webView.frame = self.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(webView)

        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    public func present(with manifest: ManifestFile, in viewController: UIViewController) {
        self.manifest = manifest

        // If prepareUrl exists, load it
        if let prepareUrlString = manifest.prepareUrl,
           let url = URL(string: prepareUrlString) {
            load(url: url)
        }
        print("IN")

        // Add to view hierarchy
        frame = viewController.view.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.addSubview(self)
    }

    public func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    @objc private func closeTapped() {
        removeFromSuperview()
        onClose?()
    }
}
