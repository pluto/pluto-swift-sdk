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

    // Log test button
    private lazy var logTestButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test Log Interceptor", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(generateTestLogs), for: .touchUpInside)
        return button
    }()

    // Text view to show captured logs
    private lazy var logOutputView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
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

        let urlProofGenerator = ProofGeneratorView(
            title: "Generate URL Proof",
            manifestUrl: URL(string: "https://util-api.pluto.dev/manifests/5ae7c353-56d9-42fc-939a-111235c2fcc5/manifest.json")!
        )

        // Add log testing section
        let logTestContainer = UIView()
        logTestContainer.translatesAutoresizingMaskIntoConstraints = false
        logTestContainer.addSubview(logTestButton)
        logTestContainer.addSubview(logOutputView)

        NSLayoutConstraint.activate([
            logTestButton.topAnchor.constraint(equalTo: logTestContainer.topAnchor),
            logTestButton.leadingAnchor.constraint(equalTo: logTestContainer.leadingAnchor),
            logTestButton.trailingAnchor.constraint(equalTo: logTestContainer.trailingAnchor),
            logTestButton.heightAnchor.constraint(equalToConstant: 44),

            logOutputView.topAnchor.constraint(equalTo: logTestButton.bottomAnchor, constant: 8),
            logOutputView.leadingAnchor.constraint(equalTo: logTestContainer.leadingAnchor),
            logOutputView.trailingAnchor.constraint(equalTo: logTestContainer.trailingAnchor),
            logOutputView.bottomAnchor.constraint(equalTo: logTestContainer.bottomAnchor),
            logOutputView.heightAnchor.constraint(equalToConstant: 150)
        ])

        stackView.addArrangedSubview(logTestContainer)
        stackView.addArrangedSubview(proofGenerator)
        stackView.addArrangedSubview(urlProofGenerator)
        stackView.addArrangedSubview(urlProofView)
        stackView.addArrangedSubview(localProofView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Log Testing

    // Keep a strong reference to the test interceptor
    private var testInterceptor: LogInterceptor?

    @objc private func generateTestLogs() {
        // Clear previous logs
        logOutputView.text = ""

        // Create a log interceptor for this test
        testInterceptor = LogInterceptor { [weak self] logMessage in
            // Update UI on main thread
            DispatchQueue.main.async {
                self?.logOutputView.text.append(logMessage)

                // Scroll to bottom
                let textView = self?.logOutputView
                let bottom = NSRange(location: textView?.text.count ?? 0, length: 0)
                textView?.scrollRangeToVisible(bottom)
            }
        }

        // Start intercepting logs
        testInterceptor?.redirectLogs()

        // Add a button to stop log redirection after testing
        let stopButton = UIButton(type: .system)
        stopButton.setTitle("Stop Log Capture", for: .normal)
        stopButton.backgroundColor = .systemRed
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 8
        stopButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.addTarget(self, action: #selector(stopLogCapture), for: .touchUpInside)

        view.addSubview(stopButton)

        NSLayoutConstraint.activate([
            stopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stopButton.widthAnchor.constraint(equalToConstant: 150),
            stopButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func stopLogCapture() {
        testInterceptor?.stopRedirecting()
        print("\n=== TEST LOG OUTPUT END ===")

        // Add a marker to the log output view
        DispatchQueue.main.async {
            self.logOutputView.text.append("\n--- LOG CAPTURE STOPPED ---\n")
        }
    }
}
