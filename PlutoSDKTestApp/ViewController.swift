import UIKit
import PlutoSwiftSDK

class ViewController: UIViewController {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let generateProofButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Generate Reddit Karma Proof", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(stackView)

        stackView.addArrangedSubview(generateProofButton)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(activityIndicator)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        generateProofButton.addTarget(self, action: #selector(generateProofTapped), for: .touchUpInside)
    }

    @objc private func generateProofTapped() {
        activityIndicator.startAnimating()
        generateProofButton.isEnabled = false
        statusLabel.text = "Generating proof..."

        Task {
            do {
                let proofResult = try await RedditKarmaProofService.generateProof()
                statusLabel.text = "Proof generated: \(proofResult)"
            } catch {
                statusLabel.text = "Error generating proof: \(error.localizedDescription)"
            }

            activityIndicator.stopAnimating()
            generateProofButton.isEnabled = true
        }
    }
}
