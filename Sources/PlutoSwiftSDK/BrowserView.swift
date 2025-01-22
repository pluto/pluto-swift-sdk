import UIKit
import WebKit

public class BrowserView: UIView, WKNavigationDelegate {
    // MARK: - Properties
    private var manifest: ManifestFile?
    private var cookies: [HTTPCookie] = []
    private var currentDOM: String = ""

    public var onClose: (() -> Void)?
    public var onCapture: (([HTTPCookie], String) -> Void)?

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
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
        let webView = WKWebView()
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    // MARK: - Initialization
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
        backgroundColor = .systemBackground
        setupContainerView()
        setupTopBar()
        setupWebView()
    }

    private func setupContainerView() {
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupTopBar() {
        containerView.addSubview(topBar)
        setupCloseButton()
        setupTitleStack()

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupCloseButton() {
        topBar.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])
    }

    private func setupTitleStack() {
        topBar.addSubview(titleStackView)
        NSLayoutConstraint.activate([
            titleStackView.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleStackView.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            titleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 8),
            titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: topBar.trailingAnchor, constant: -8)
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

    // MARK: - Public Methods
    public func present(with manifest: ManifestFile, in viewController: UIViewController) {
        self.manifest = manifest

        // Add self to view hierarchy before loading URL
        translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: viewController.view.topAnchor),
            leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])

        // Load URL after view is set up
        if let prepareUrlString = manifest.prepareUrl,
           let url = URL(string: prepareUrlString) {
            DispatchQueue.main.async {
                self.webView.load(URLRequest(url: url))
            }
        }
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        removeFromSuperview()
        onClose?()
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
