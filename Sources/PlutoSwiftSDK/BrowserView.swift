import UIKit
import WebKit

public class BrowserView: UIView, WKNavigationDelegate {

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let topBar: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let lockImageView: UIImageView = {
        let img = UIImageView(image: UIImage(systemName: "lock.fill"))
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        img.isHidden = true  // Start hidden
        return img
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        lbl.lineBreakMode = .byTruncatingTail
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var titleStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [lockImageView, titleLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let webView: WKWebView = {
        let wv = WKWebView()
        wv.scrollView.contentInsetAdjustmentBehavior = .automatic
        wv.translatesAutoresizingMaskIntoConstraints = false
        return wv
    }()
    
    private var manifest: ManifestFile?
    public var onClose: (() -> Void)?
    
    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }
    
    // MARK: - Setup Layout
    
    private func setupLayout() {
        backgroundColor = .systemBackground
        
        // Container fills our entire view
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Top bar pinned to safe area top
        containerView.addSubview(topBar)
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Close button on the far left
        topBar.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])
        
        // Title stack (lock + label) in the center
        topBar.addSubview(titleStackView)
        NSLayoutConstraint.activate([
            titleStackView.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleStackView.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            titleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 8),
            titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: topBar.trailingAnchor, constant: -8),
        ])
        
        // WebView below top bar
        containerView.addSubview(webView)
        webView.navigationDelegate = self
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    // MARK: - Present
    
    public func present(with manifest: ManifestFile, in viewController: UIViewController) {
        self.manifest = manifest
        
        if let prepareUrlString = manifest.prepareUrl,
           let url = URL(string: prepareUrlString) {
            webView.load(URLRequest(url: url))
        }
        
        translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: viewController.view.topAnchor),
            leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        removeFromSuperview()
        onClose?()
    }
    
    // MARK: - WKNavigationDelegate
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Update the title
        let siteTitle = webView.title ?? ""
        titleLabel.text = siteTitle
        
        // Check if https
        let isHTTPS = (webView.url?.scheme?.lowercased() == "https")
        
        // Show the lock only if site is https AND the title is not empty
        if isHTTPS && !siteTitle.isEmpty {
            lockImageView.isHidden = false
            lockImageView.tintColor = .systemGreen // always green
        } else {
            lockImageView.isHidden = true
        }
    }
}
