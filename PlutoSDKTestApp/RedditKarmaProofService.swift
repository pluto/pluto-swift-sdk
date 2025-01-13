import PlutoSwiftSDK
import Foundation

class RedditKarmaProofService {
    static func generateProof() async throws -> String {
        let manifest = ManifestFile(
            manifestVersion: "2",
            id: "reddit-user-karma",
            title: "Total Reddit Karma",
            description: "Generate a proof that you have a certain amount of karma",
            prepareUrl: "https://www.reddit.com/login/",
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
        
        return try await PlutoSwiftSDK.generateProof(manifest: manifest) { status in
            print("Proof status changed: \(status)")
        }
    }}
