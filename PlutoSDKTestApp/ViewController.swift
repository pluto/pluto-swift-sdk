import UIKit
import PlutoSwiftSDK

class ViewController: UIViewController {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 40
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(stackView)

        let proofGenerator = ProofGeneratorView(manifest: SampleData.manifest)
        let urlProofView = BrowserProofView(
            source: .url(SampleData.manifestUrl),
            parentViewController: self
        )
        let localProofView = BrowserProofView(
            source: .local(SampleData.manifest, SampleData.prepareJS),
            parentViewController: self
        )

        
        stackView.addArrangedSubview(proofGenerator)
        stackView.addArrangedSubview(urlProofView)
        stackView.addArrangedSubview(localProofView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}
