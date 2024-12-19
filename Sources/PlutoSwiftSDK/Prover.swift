import Foundation

public enum ProofStatus {
    case loading
    case success
    case failure
}

struct RawProverResponse: Codable {
    let proof: String?
    let error: String?
}

public class Prover {
    private let notaryHost = "notary.pluto.dev"
    private let notaryPort = 443
    private let maxSentData = 10000
    private let maxRecvData = 10000

    public init() {}

    public func generateProof(manifest: ManifestFile, onStatusChange: ((ProofStatus) -> Void)? = nil) async throws -> String {
        // Prepare target body and ensure it's base64 encoded
        var targetBody = manifest.request.body ?? ""
        
        if let bodyData = targetBody.data(using: .utf8) {
            targetBody = bodyData.base64EncodedString()
        } else {
            print("Warning: Failed to encode body to Base64.")
        }
        
        let config: [String: Any] = [
            "mode": manifest.mode?.rawValue ?? Mode.Origo.rawValue,
            "notary_host": notaryHost,
            "notary_port": notaryPort,
            "target_method": manifest.request.method.rawValue,
            "target_url": manifest.request.url,
            "target_headers": manifest.request.headers.merging(manifest.request.extra?.headers ?? [:]) { (_, new) in new },
            "target_body": targetBody,
            "max_sent_data": maxSentData,
            "max_recv_data": maxRecvData,
            "proving": ["manifest": manifest]
        ]
        
        onStatusChange?(.loading)
        
        do {
            // Perform Objective-C Prover Call
            let responseString = try await self.callObjectiveCProver(with: config)
            guard let responseData = responseString.data(using: .utf8) else {
                throw ProverError.invalidResponse
            }
            
            let response = try JSONDecoder().decode(RawProverResponse.self, from: responseData)
            
            if let error = response.error {
                onStatusChange?(.failure)
                throw ProverError.custom(error)
            } else if let proof = response.proof {
                onStatusChange?(.success)
                return proof
            } else {
                onStatusChange?(.failure)
                throw ProverError.invalidResponse
            }
        } catch {
            // Ensure .failure is called on any error
            onStatusChange?(.failure)
            throw error
        }
    }


    // Objective-C Prover Function
    internal func callObjectiveCProver(with config: [String: Any]) async throws -> String {
        // Replace this stub with the actual Objective-C implementation
        throw ProverError.notImplemented
    }
}

// Prover Errors
enum ProverError: Error {
    case notImplemented
    case invalidResponse
    case custom(String)
}
