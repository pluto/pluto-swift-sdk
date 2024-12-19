import Foundation

public class PlutoSwiftSDK {
    public static func generateProof(
        manifest: ManifestFile,
        onStatusChange: ((ProofStatus) -> Void)? = nil,
        prover: Prover = Prover()
    ) async throws -> String {
        return try await prover.generateProof(manifest: manifest, onStatusChange: onStatusChange)
    }
}
