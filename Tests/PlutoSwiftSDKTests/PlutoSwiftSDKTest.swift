import XCTest
@testable import PlutoSwiftSDK

final class PlutoSwiftSDKTest: XCTestCase {
    func testGenerateProof() throws {
        let proof = Prover.generateProof(config: "TestConfig")
        XCTAssertEqual(proof, "Generated proof for: TestConfig")
    }
    
    func testManifestParser_WithValidJSON_ShouldParseCorrectly() {
        let jsonString = """
        {
            "manifestVersion": "1.0",
            "id": "1234",
            "title": "Test Manifest",
            "description": "This is a test.",
            "prepareUrl": "https://example.com/prepare",
            "mode": "TLSN",
            "request": {
                "method": "POST",
                "url": "https://example.com/api",
                "headers": { "Content-Type": "application/json" },
                "vars": { "var1": { "type": "string", "length": 2 } },
                "body": "{\\"key\\":\\"value\\"}",
                "extra": {
                    "method": "GET",
                    "url": "https://example.com/extra",
                    "headers": { "Accept": "application/json" }
                }
            },
            "response": {
                "status": "200",
                "headers": { "Server": "nginx" },
                "body": {
                    "json": ["key", "value"]
                }
            },
            "debugLogs": ["Log1", "Log2"]
        }
        """

        let manifest = ManifestParser.parseManifest(from: jsonString)
        
        // Assert: Verify parsed content
        XCTAssertNotNil(manifest, "Manifest should not be nil")
        XCTAssertEqual(manifest?.manifestVersion, "1.0")
        XCTAssertEqual(manifest?.id, "1234")
        XCTAssertEqual(manifest?.title, "Test Manifest")
        XCTAssertEqual(manifest?.description, "This is a test.")
        XCTAssertEqual(manifest?.prepareUrl, "https://example.com/prepare")
        XCTAssertEqual(manifest?.mode, .TLSN)

        // Verify request
        let request = manifest?.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.method, .POST)
        XCTAssertEqual(request?.url, "https://example.com/api")
        XCTAssertEqual(request?.headers["Content-Type"], "application/json")
        XCTAssertEqual(request?.body, "{\"key\":\"value\"}")
        XCTAssertEqual(request?.vars?["var1"]?.type, "string")
        XCTAssertEqual(request?.vars?["var1"]?.length, 2)

        // Verify nested 'extra' request
        let extraRequest = request?.extra
        XCTAssertNotNil(extraRequest)
        XCTAssertEqual(extraRequest?.method, .GET)
        XCTAssertEqual(extraRequest?.url, "https://example.com/extra")
        XCTAssertEqual(extraRequest?.headers["Accept"], "application/json")

        // Verify response
        let response = manifest?.response
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.status, "200")
        XCTAssertEqual(response?.headers["Server"], "nginx")
        XCTAssertEqual(response?.body.json.first, "key")

        // Verify debugLogs
        XCTAssertEqual(manifest?.debugLogs, ["Log1", "Log2"])
    }
}
