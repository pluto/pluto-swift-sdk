import XCTest
@testable import PlutoSwiftSDK

final class ManifestParserTests: XCTestCase {
    var manifestAsString: String!
    var manifest: ManifestFile!

    override func setUp() {
        super.setUp()
        manifestAsString = ManifestTestFactory.makeManifest(asJSONString: true) as? String
        manifest = ManifestTestFactory.makeManifest() as? ManifestFile
    }

    func testManifestParser_WithValidJSON_ShouldParseCorrectly() {
        // Arrange
        guard let manifestAsString = ManifestTestFactory.makeManifest(asJSONString: true) as? String else {
            XCTFail("Failed to generate manifest JSON string.")
            return
        }
        let expectedManifest = ManifestTestFactory.makeManifest() as? ManifestFile

        // Act
        let _manifest = ManifestParser.parseManifest(from: manifestAsString)

        // Assert
        XCTAssertNotNil(_manifest, "Manifest should not be nil")
        XCTAssertEqual(_manifest?.manifestVersion, expectedManifest?.manifestVersion)
        XCTAssertEqual(_manifest?.id, expectedManifest?.id)
        XCTAssertEqual(_manifest?.title, expectedManifest?.title)
        XCTAssertEqual(_manifest?.description, expectedManifest?.description)
        XCTAssertEqual(_manifest?.prepareUrl, expectedManifest?.prepareUrl)
        XCTAssertEqual(_manifest?.mode, expectedManifest?.mode)

        // Verify request
        let request = _manifest?.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.method, expectedManifest?.request.method)
        XCTAssertEqual(request?.url, expectedManifest?.request.url)
        XCTAssertEqual(request?.headers["Content-Type"], expectedManifest?.request.headers["Content-Type"])

        // Compare request body using underlying values
        if let actualBody = request?.body?.value as? [String: String],
           let expectedBody = expectedManifest?.request.body?.value as? [String: String] {
            XCTAssertEqual(actualBody, expectedBody)
        } else {
            XCTFail("Failed to compare request body values")
        }

        // Verify vars
        XCTAssertEqual(request?.vars["var1"]?.type, expectedManifest?.request.vars["var1"]?.type)
        XCTAssertEqual(request?.vars["var1"]?.regex, expectedManifest?.request.vars["var1"]?.regex)
        XCTAssertEqual(request?.vars["var1"]?.length, expectedManifest?.request.vars["var1"]?.length)

        // Verify nested `extra` request
        let extraRequest = request?.extra
        XCTAssertNotNil(extraRequest)
        XCTAssertEqual(extraRequest?.method, expectedManifest?.request.extra?.method)
        XCTAssertEqual(extraRequest?.url, expectedManifest?.request.extra?.url)

        // Compare headers safely
        if let actualHeaders = extraRequest?.headers,
           let expectedHeaders = expectedManifest?.request.extra?.headers {
            XCTAssertEqual(actualHeaders["Accept"], expectedHeaders["Accept"])
        } else {
            XCTFail("Failed to compare extra request headers")
        }

        // Verify response
        let response = _manifest?.response
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.status, expectedManifest?.response.status)
        XCTAssertEqual(response?.headers["Server"], expectedManifest?.response.headers["Server"])

        // Compare AnyCodable values
        if let actualJson = response?.body.json.first?.value as? String,
           let expectedJson = expectedManifest?.response.body.json.first?.value as? String {
            XCTAssertEqual(actualJson, expectedJson)
        } else {
            XCTFail("Failed to compare response body JSON values")
        }
    }

}
