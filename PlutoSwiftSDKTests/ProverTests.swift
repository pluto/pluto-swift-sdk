import XCTest
@testable import PlutoSwiftSDK

final class ProverTests: XCTestCase {
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

    func testProve_Success() async throws {
        // Arrange
        let prover = MockProver()
        prover.mockResponse = """
        {
            "proof": "mock-proof-data",
            "error": null
        }
        """

        let manifest = ManifestTestFactory.makeManifest() as! ManifestFile

        var statusUpdates: [ProofStatus] = []

        // Act
        let proof = try await prover.generateProof(
            manifest: manifest,
            onStatusChange: { status in
                statusUpdates.append(status)
            }
        )

        // Assert
        XCTAssertEqual(proof, "mock-proof-data")
        XCTAssertEqual(statusUpdates, [.loading, .success], "Expected status updates to be [.loading, .success].")
    }
    
    func testProve_Failure_InvalidResponse() async throws {
        // Arrange
        let prover = MockProver()
        prover.shouldThrowError = true

        let manifest = ManifestTestFactory.makeManifest(
            mode: .TLSN,
            requestMethod: .GET,
            responseStatus: "404",
            responseJson: []
        ) as! ManifestFile

        var statusUpdates: [ProofStatus] = []

        // Act & Assert
        do {
            _ = try await prover.generateProof(
                manifest: manifest,
                onStatusChange: { status in
                    statusUpdates.append(status)
                }
            )
            XCTFail("Expected failure, but got success.")
        } catch {
            XCTAssertTrue(error is ProverError)
            XCTAssertEqual(statusUpdates, [.loading, .failure], "Expected status updates to be [.loading, .failure].")
        }
    }
}
