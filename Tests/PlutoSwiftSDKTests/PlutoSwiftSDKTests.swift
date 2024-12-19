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

    func testGenerateProof_Success() async throws {
        // Arrange
        let mockProver = MockProver()
        mockProver.mockResponse = """
        {
            "proof": "mock-proof-data",
            "error": null
        }
        """

        let manifest = ManifestTestFactory.makeManifest(
            mode: .Origo
        ) as! ManifestFile

        var statusUpdates: [ProofStatus] = []

        // Act
        let proof = try await PlutoSwiftSDK.generateProof(
            manifest: manifest,
            onStatusChange: { status in
                statusUpdates.append(status)
            },
            prover: mockProver
        )

        // Assert
        XCTAssertEqual(proof, "mock-proof-data")
        XCTAssertEqual(statusUpdates, [.loading, .success], "Expected status updates to be [.loading, .success].")
    }

    func testGenerateProof_Failure_InvalidResponse() async throws {
        // Arrange
        let mockProver = MockProver()
        mockProver.shouldThrowError = true

        let manifest = ManifestTestFactory.makeManifest(
            mode: .TLSN,
            requestMethod: .GET,
            responseStatus: "404"
        ) as! ManifestFile

        var statusUpdates: [ProofStatus] = []

        // Act & Assert
        do {
            _ = try await PlutoSwiftSDK.generateProof(
                manifest: manifest,
                onStatusChange: { status in
                    statusUpdates.append(status)
                },
                prover: mockProver
            )
            XCTFail("Expected failure, but got success.")
        } catch {
            XCTAssertTrue(error is ProverError)
            XCTAssertEqual(statusUpdates, [.loading, .failure], "Expected status updates to be [.loading, .failure].")
        }
    }
}
