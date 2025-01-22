import Foundation

// MARK: - Main SDK Interface
public enum PlutoSwiftSDK {
    // MARK: - Public Methods
    public static func generateProof(
        manifest: ManifestFile,
        onStatusChange: ((ProofStatus) -> Void)? = nil,
        prover: Prover = Prover()
    ) async throws -> String {
        return try await prover.generateProof(
            manifest: manifest,
            onStatusChange: onStatusChange
        )
    }

    public static func generateProof(
        manifestURL: URL,
        onStatusChange: ((ProofStatus) -> Void)? = nil,
        prover: Prover = Prover()
    ) async throws -> String {
        // Download and decode the manifest JSON file
        let (data, _) = try await URLSession.shared.data(from: manifestURL)
        let manifest = try JSONDecoder().decode(ManifestFile.self, from: data)

        // Call the existing generateProof with the decoded manifest
        return try await generateProof(
            manifest: manifest,
            onStatusChange: onStatusChange,
            prover: prover
        )
    }
}

// MARK: - Manifest Parser Interface
extension PlutoSwiftSDK {
    public static func parseManifest(from jsonString: String) -> ManifestFile? {
        return ManifestParser.parseManifest(from: jsonString)
    }
}
