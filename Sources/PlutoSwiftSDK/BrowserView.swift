import UIKit
import WebKit

// Internal since it's only used internally
internal class BrowserView: UIView, WKNavigationDelegate {
    // MARK: - Properties
    private var manifest: ManifestFile?
    private var cookies: [HTTPCookie] = []
    private var currentDOM: String = ""

    public var onClose: (() -> Void)?
    public var onCapture: (([HTTPCookie], String) -> Void)?

    private var containerBottomConstraint: NSLayoutConstraint?

    // MARK: - UI Components
    private let dimmingView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        // For top corners only:
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let topBar: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let lockImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "lock.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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

    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    // MARK: - Setup
    private func setupLayout() {
        backgroundColor = .clear

        // 1) Dimming view
        addSubview(dimmingView)
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // 2) Container
        addSubview(containerView)

        // We won't pin top directly. Instead we fix the container's height to fill the screen,
        // and animate the bottom constraint from "offscreen" to "0".
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerBottomConstraint!,
            // Make the container's height = entire superview (for full-screen),
            // or something smaller if you want a partial sheet:
            containerView.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        setupTopBar()
        setupWebView()
    }

    private func setupTopBar() {
        containerView.addSubview(topBar)
        topBar.addSubview(closeButton)
        topBar.addSubview(titleStackView)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44),

            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            titleStackView.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleStackView.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            titleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 8),
            titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: topBar.trailingAnchor, constant: -8),
        ])
    }

    private func setupWebView() {
        containerView.addSubview(webView)
        webView.navigationDelegate = self
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    // MARK: - Public
    public func present(with manifest: ManifestFile, in viewController: UIViewController) {
        self.manifest = manifest

        // Add self to parent
        translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: viewController.view.topAnchor),
            leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])

        // Start offscreen by setting bottom anchor constant = container height
        // For a full screen, use the parent's bounds:
        let screenHeight = viewController.view.bounds.height
        containerBottomConstraint?.constant = screenHeight
        dimmingView.alpha = 0

        // Force layout
        viewController.view.layoutIfNeeded()

        // Animate upward
        containerBottomConstraint?.constant = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            viewController.view.layoutIfNeeded()
            self.dimmingView.alpha = 1
        }, completion: nil)

        // Optionally load the URL
        if let prepareUrlString = manifest.prepareUrl,
           let url = URL(string: prepareUrlString) {
            webView.load(URLRequest(url: url))
        }
    }

    // Slide down & remove
    private func dismissSheet() {
        guard let superview = superview else { return }
        let screenHeight = superview.bounds.height
        containerBottomConstraint?.constant = screenHeight

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            superview.layoutIfNeeded()
            self.dimmingView.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            self.onClose?()
        })
    }

    @objc private func closeTapped() {
        dismissSheet()
    }

    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateUI()
        captureData()
    }

    private func updateUI() {
        let siteTitle = webView.title ?? ""
        titleLabel.text = siteTitle
        let isHTTPS = (webView.url?.scheme?.lowercased() == "https")
        lockImageView.isHidden = !(isHTTPS && !siteTitle.isEmpty)
        lockImageView.tintColor = .systemGreen
    }

    private func captureData() {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            self?.cookies = cookies

            let javascript = "document.documentElement.outerHTML"
            self?.webView.evaluateJavaScript(javascript) { [weak self] result, _ in
                guard let self = self,
                      let html = result as? String else { return }
                self.currentDOM = html
                self.onCapture?(cookies, html)
            }
        }
    }
}
