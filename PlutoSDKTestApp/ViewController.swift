import UIKit
import PlutoSwiftSDK

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Test SDK API
        let proof = Prover.generateProof(config: "TestConfig")
        print("Proof Result:", proof)

        let browserView = BrowserView(frame: self.view.bounds)
        browserView.load(url: URL(string: "https://example.com")!)
        self.view.addSubview(browserView)
    }
}
