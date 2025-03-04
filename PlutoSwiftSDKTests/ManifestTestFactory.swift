import Foundation
@testable import PlutoSwiftSDK

final class ManifestTestFactory {

    // Generate a ManifestFile or JSON String
    static func makeManifest(
        id: String = "test-id",
        title: String = "This is a test.",
        description: String = "A test manifest",
        mode: Mode = .Origo,
        requestMethod: Methods = .GET,
        requestUrl: String = "https://example.com/api",
        requestHeaders: [String: String] = ["Content-Type": "application/json"],
        requestBody: AnyCodable? = AnyCodable(["key": "value"]),
        requestVars: [String: ManifestVars]? = [
            "var1": ManifestVars(type: "string", regex: "[A-Za-z]+", length: 10)
        ],
        extraRequest: ManifestFileRequestExtra? = ManifestFileRequestExtra(
            method: .GET,
            url: "https://example.com/extra",
            headers: ["Accept": "application/json"]
        ),
        responseStatus: String = "200",
        responseHeaders: [String: String] = ["Server": "nginx"],
        responseJson: [AnyCodable] = [AnyCodable("key:value")],
        asJSONString: Bool = false // Added option to return JSON string
    ) -> Any? {
        let request = ManifestFileRequest(
            method: requestMethod,
            url: requestUrl,
            headers: requestHeaders,
            body: requestBody,
            vars: requestVars,
            extra: extraRequest
        )

        let response = ManifestFileResponse(
            status: responseStatus,
            headers: responseHeaders,
            body: ManifestFileResponse.ResponseBody(json: responseJson)
        )

        let manifest = ManifestFile(
            manifestVersion: "1.0",
            id: id,
            title: title,
            description: description,
            prepareUrl: "https://example.com/prepare",
            mode: mode,
            request: request,
            response: response
        )

        if asJSONString {
            do {
                let jsonData = try JSONEncoder().encode(manifest)
                return String(data: jsonData, encoding: .utf8)
            } catch {
                print("Error encoding manifest to JSON: \(error)")
                return nil
            }
        } else {
            return manifest
        }
    }
}
