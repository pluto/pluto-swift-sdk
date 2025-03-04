import UIKit
import PlutoSwiftSDK

class ProofGeneratorView: UIView {
    private let manifest: ManifestFile?
    private let manifestUrl: URL?

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let generateButton: PlutoButton
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    init(title: String = "Generate Proof", manifest: ManifestFile? = nil, manifestUrl: URL? = nil) {
        self.manifest = manifest
        self.manifestUrl = manifestUrl
        self.generateButton = PlutoButton(title: title)
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.addArrangedSubview(generateButton)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(activityIndicator)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        generateButton.addAction(UIAction { [weak self] _ in
            Task { await self?.generateProof() }
        }, for: .touchUpInside)
    }

    @objc private func generateProof() async {
        activityIndicator.startAnimating()
        generateButton.isEnabled = false
        statusLabel.text = "Generating proof..."

        do {
            let proofResult: String
            if let manifest = manifest {
                proofResult = try await Pluto.generateProof(manifest: manifest) { status in
                    print("Proof status changed: \(status)")
                }
            } else if let manifestUrl = manifestUrl {
                proofResult = try await Pluto.generateProof(manifestURL: manifestUrl) { status in
                    print("Proof status changed: \(status)")
                }
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No manifest or URL provided"])
            }
            statusLabel.text = "Proof generated: \(proofResult)"
        } catch {
            statusLabel.text = "Error generating proof: \(error.localizedDescription)"
        }

        activityIndicator.stopAnimating()
        generateButton.isEnabled = true
    }
}
