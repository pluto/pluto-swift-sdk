import UIKit
import PlutoSwiftSDK

class ProofGeneratorView: UIView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let generateButton: PlutoButton = {
        let button = PlutoButton(title: "Generate Proof")
        return button
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Ready to generate proof"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let manifest: ManifestFile

    init(manifest: ManifestFile) {
        self.manifest = manifest
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

    private func generateProof() async {
        activityIndicator.startAnimating()
        generateButton.isEnabled = false
        statusLabel.text = "Generating proof..."

        do {
            let proofResult = try await PlutoSwiftSDK.generateProof(manifest: manifest) { status in
                print("Proof status changed: \(status)")
            }
            statusLabel.text = "Proof generated: \(proofResult)"
        } catch {
            statusLabel.text = "Error generating proof: \(error.localizedDescription)"
        }

        activityIndicator.stopAnimating()
        generateButton.isEnabled = true
    }
}
