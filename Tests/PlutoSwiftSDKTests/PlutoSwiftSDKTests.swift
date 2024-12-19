import XCTest
@testable import PlutoSwiftSDK

final class SDKPublicEntryPointTests: XCTestCase {
    class MockProver: Prover {
        var mockResponse: String?
        var shouldThrowError: Bool = false

        override func callObjectiveCProver(with config: [String: Any]) async throws -> String {
            if shouldThrowError {
                throw ProverError.invalidResponse
            }
            return mockResponse ?? ""
        }
    }

    // Success Case: Validate successful proof generation via entry point
    func testGenerateProof_Success() async throws {
        // Arrange
        let mockProver = MockProver()
        mockProver.mockResponse = """
        {
            "proof": "mock-proof-data",
            "error": null
        }
        """

        let manifest = ManifestFile(
            manifestVersion: "1.0",
            id: "test-id",
            title: "Test Manifest",
            description: "A test manifest",
            prepareUrl: nil,
            mode: .Origo,
            request: ManifestFileRequest(
                method: .POST,
                url: "https://example.com",
                headers: ["Content-Type": "application/json"],
                body: "{\"key\":\"value\"}"
            ),
            response: ManifestFileResponse(
                status: "200",
                headers: ["Server": "nginx"],
                body: ManifestFileResponse.ResponseBody(
                    json: ["key:value"]
                )
            )
        )

        var statusUpdates: [ProofStatus] = []

        // Act
        let proof = try await PlutoSwiftSDK.generateProof(
            manifest: manifest,
            onStatusChange: { status in
                statusUpdates.append(status)
            },
            prover: mockProver // Inject mock prover
        )

        // Assert
        XCTAssertEqual(proof, "mock-proof-data")
        XCTAssertEqual(statusUpdates, [.loading, .success], "Expected status updates to be [.loading, .success].")
    }

    // Failure Case: Validate failure due to invalid response via entry point
    func testGenerateProof_Failure_InvalidResponse() async throws {
        // Arrange
        let mockProver = MockProver()
        mockProver.shouldThrowError = true

        let manifest = ManifestFile(
            manifestVersion: "1.0",
            id: "test-id",
            title: "Test Manifest",
            description: "A test manifest",
            prepareUrl: nil,
            mode: .TLSN,
            request: ManifestFileRequest(
                method: .GET,
                url: "https://example.com",
                headers: [:],
                body: nil
            ),
            response: ManifestFileResponse(
                status: "404",
                headers: [:],
                body: ManifestFileResponse.ResponseBody(
                    json: []
                )
            )
        )

        var statusUpdates: [ProofStatus] = []

        // Act & Assert
        do {
            _ = try await PlutoSwiftSDK.generateProof(
                manifest: manifest,
                onStatusChange: { status in
                    statusUpdates.append(status)
                },
                prover: mockProver // Inject mock prover
            )
            XCTFail("Expected failure, but got success.")
        } catch {
            XCTAssertTrue(error is ProverError)
            XCTAssertEqual(statusUpdates, [.loading, .failure], "Expected status updates to be [.loading, .failure].")
        }
    }
}
