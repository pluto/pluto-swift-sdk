import UIKit
import PlutoSwiftSDK

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Create the request portion
        let exampleRequest = ManifestFileRequest(
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
        )

        // 2. Create the response portion
        let exampleResponse = ManifestFileResponse(
            status: "200",
            headers: ["Content-Type": "application/json"],
            body: ManifestFileResponse.ResponseBody(json: ["data", "redditorInfoByName", "karma", "total"])
        )

        // 3. Put everything together in a ManifestFile
        let exampleManifest = ManifestFile(
            manifestVersion: "2",
            id: "reddit-user-karma",
            title: "Total Reddit Karma",
            description: "Generate a proof that you have a certain amount of karma",
            prepareUrl: "https://www.reddit.com/login/",
            request: exampleRequest,
            response: exampleResponse
        )

        // 4. Call generateProof, optionally handling status changes
        Task {
            do {
                let proof = try await PlutoSwiftSDK.generateProof(manifest: exampleManifest) { status in
                    print("Proof status changed: \(status)")
                }
                print("Generated proof: \(proof)")
            } catch {
                print("Error: \(error)")
            }
        }

        // Test SDK API
//        let proof = Prover.generateProof(config: "TestConfig")
//        print("Proof Result:", proof)
//
//        let browserView = BrowserView(frame: self.view.bounds)
//        browserView.load(url: URL(string: "https://example.com")!)
//        self.view.addSubview(browserView)
    }
}
