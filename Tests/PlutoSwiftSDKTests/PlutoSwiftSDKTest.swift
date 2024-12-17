import XCTest
@testable import PlutoSwiftSDK

final class PlutoSwiftSDKTest: XCTestCase {
    func testGenerateProof() throws {
        let proof = Prover.generateProof(config: "TestConfig")
        XCTAssertEqual(proof, "Generated proof for: TestConfig")
    }
}
