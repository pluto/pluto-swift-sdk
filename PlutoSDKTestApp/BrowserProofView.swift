import UIKit
import PlutoSwiftSDK

class BrowserProofView: UIView {
    enum ProofSource {
        case url(URL)
        case local(ManifestFile, String)
    }

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let openBrowserButton: PlutoButton = {
        let button = PlutoButton(title: "Open Browser")
        return button
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let proofSource: ProofSource
    private weak var parentViewController: UIViewController?

    init(source: ProofSource, parentViewController: UIViewController) {
        self.proofSource = source
        self.parentViewController = parentViewController
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.addArrangedSubview(openBrowserButton)
        stackView.addArrangedSubview(statusLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        switch proofSource {
        case .url:
            openBrowserButton.setTitle("Open Browser (URL)", for: .normal)
        case .local:
            openBrowserButton.setTitle("Open Browser (Local)", for: .normal)
        }

        openBrowserButton.addAction(UIAction { [weak self] _ in
            Task { await self?.openBrowser() }
        }, for: .touchUpInside)
    }

    private func openBrowser() async {
        guard let parentVC = parentViewController else { return }

        do {
            let builder = RequestBuilder(parentViewController: parentVC)

            switch proofSource {
            case .url(let url):
                try await builder.withManifestUrl(url)
            case .local(let manifest, let prepareJS):
                builder.withManifest(manifest).withPrepareJS(prepareJS)
            }

            try await builder.showBrowserView { [weak self] updatedManifest in
                self?.statusLabel.text = "Manifest constructed"

                Task {
                    do {
                        let proofResult = try await Pluto.generateProof(manifest: updatedManifest) { status in
                            print("Proof status changed: \(status)")
                        }
                        self?.statusLabel.text = "Proof generated: \(proofResult)"
                    } catch {
                        self?.statusLabel.text = "Error generating proof: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            statusLabel.text = "Error: \(error.localizedDescription)"
        }
    }
}
