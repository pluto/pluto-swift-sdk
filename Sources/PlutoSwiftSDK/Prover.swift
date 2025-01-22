import Foundation
import ProverBinary

// MARK: - Types
public enum ProofStatus {
    case loading
    case success
    case failure
}

struct RawProverResponse: Codable {
    let proof: String?
    let error: String?
}

// MARK: - Prover
public class Prover {
    // MARK: - Properties
    private let notaryHost = "4f630ed.notary.pluto.dev"
    private let notaryPort = 443
    private let maxSentData = 10000
    private let maxRecvData = 10000

    // MARK: - Initialization
    public init() {}

    // MARK: - Public Methods
    public func generateProof(manifest: ManifestFile, onStatusChange: ((ProofStatus) -> Void)? = nil) async throws -> String {
        let targetBody = manifest.request.body ?? AnyCodable("")

        do {
            let config = try buildConfig(manifest: manifest, targetBody: targetBody)
            onStatusChange?(.loading)

            do {
                let responseString = try await callProver(with: config)
                return try handleProverResponse(responseString, onStatusChange: onStatusChange)
            } catch {
                onStatusChange?(.failure)
                throw error
            }
        } catch {
            throw error
        }
    }

    // MARK: - Private Methods
    private func buildConfig(manifest: ManifestFile, targetBody: AnyCodable) throws -> [String: Any] {
        let base64Body = try targetBody.toBase64()
        let manifestData = try JSONEncoder().encode(manifest)
        guard let manifestDict = try JSONSerialization.jsonObject(with: manifestData) as? [String: Any] else {
            throw ProverError.invalidResponse
        }

        return [
            "mode": manifest.mode?.rawValue ?? Mode.Origo.rawValue,
            "notary_host": notaryHost,
            "notary_port": notaryPort,
            "target_method": manifest.request.method.rawValue,
            "target_url": manifest.request.url,
            "target_headers": manifest.request.headers.merging(manifest.request.extra?.headers ?? [:]) { (_, new) in new },
            "target_body": base64Body,
            "max_sent_data": maxSentData,
            "max_recv_data": maxRecvData,
            "proving": ["manifest": manifestDict]
        ]
    }

    private func callProver(with configJSON: [String: Any]) async throws -> String? {
        let jsonData = try JSONSerialization.data(withJSONObject: configJSON)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ProverError.invalidResponse
        }

        guard let resultPtr = prover(jsonString) else { return nil }
        return String(cString: resultPtr)
    }

    private func handleProverResponse(_ responseString: String?, onStatusChange: ((ProofStatus) -> Void)?) throws -> String {
        guard let responseData = responseString?.data(using: .utf8) else {
            throw ProverError.invalidResponse
        }

        let response = try JSONDecoder().decode(RawProverResponse.self, from: responseData)

        if let error = response.error {
            onStatusChange?(.failure)
            throw ProverError.custom(error)
        }

        if let proof = response.proof {
            onStatusChange?(.success)
            return proof
        }

        onStatusChange?(.failure)
        throw ProverError.invalidResponse
    }
}

// MARK: - Errors
enum ProverError: Error {
    case notImplemented
    case invalidResponse
    case custom(String)
}
