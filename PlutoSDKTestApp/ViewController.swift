import UIKit
import PlutoSwiftSDK

class ViewController: UIViewController {
    let manifest = ManifestFile(
        manifestVersion: "2",
        id: "reddit-user-karma",
        title: "Total Reddit Karma",
        description: "Generate a proof that you have a certain amount of karma",
        prepareUrl: "https://old.reddit.com/login/?dest=https%3A%2F%2Fold.reddit.com%2F",
        request: ManifestFileRequest(
            method: .POST,
            url: "https://gql.reddit.com/",
            headers: ["Authorization": "Bearer <% authToken %>"],
            body: AnyCodable([
                "id": "db6eb1356b13",
                "variables": [
                    "name": "<% userId %>"
                ]
            ]),
            vars:  ["userId": ManifestVars(), "authToken": ManifestVars()],
            extra: ManifestFileRequestExtra(
                headers: [
                    "User-Agent": "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36",
                    "Content-Type": "application/json"
                ]
            )
        ),
        response: ManifestFileResponse(
            status: "200",
            headers: ["Content-Type": "application/json"],
            body: ManifestFileResponse.ResponseBody(json: ["data", "redditorInfoByName", "karma", "total"])
        )
    )

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

    private let openBrowserButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open Browser", for: .normal)
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

    private var requestBuilder: RequestBuilder?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(stackView)

        stackView.addArrangedSubview(generateProofButton)
        stackView.addArrangedSubview(openBrowserButton)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(activityIndicator)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        generateProofButton.addTarget(self, action: #selector(generateProofTapped), for: .touchUpInside)
        openBrowserButton.addTarget(self, action: #selector(openBrowserTapped), for: .touchUpInside)
    }

    @objc private func generateProofTapped() {
        activityIndicator.startAnimating()
        generateProofButton.isEnabled = false
        statusLabel.text = "Generating proof..."

        Task {
            do {
                let proofResult = try await PlutoSwiftSDK.generateProof(manifest: manifest) { status in
                    print("Proof status changed: \(status)")
                }
                statusLabel.text = "Proof generated: \(proofResult)"
            } catch {
                statusLabel.text = "Error generating proof: \(error.localizedDescription)"
            }

            activityIndicator.stopAnimating()
            generateProofButton.isEnabled = true
        }
    }

    @objc private func openBrowserTapped() {
        do {
            try RequestBuilder(parentViewController: self)
                .withManifest(manifest)
                .withPrepareJS("""
                    function prepare(ctx, manifest) {
                        const cookies = ctx.cookies;
                        const doc = ctx.doc;

                        try {
                            // Auth Token
                            if (cookies["token_v2"]) {
                                manifest.request.set("authToken", cookies["token_v2"].value);
                            }

                            // User ID
                            const userLink = doc.querySelector('span.user > a[href*="/user/"]');
                            if (userLink) {
                                manifest.request.set(
                                    "userId",
                                    userLink.getAttribute("href").split("/user/")[1].replace("/", "")
                                );
                            }

                            return (
                                !manifest.request.get("body").variables.name.includes("<%") &&
                                !!manifest.request.getHeader("Authorization")
                            );
                        } catch (e) {
                            console.error("Error in getBody:", e);
                            return false;
                        }
                    }
                """)
                .showBrowserView { [weak self] updatedManifest in
                    self?.statusLabel.text = "Manifest constructed"

                    Task {
                        do {
                            let proofResult = try await PlutoSwiftSDK.generateProof(manifest: updatedManifest) { status in
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
