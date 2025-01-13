import Foundation
import ProverBinary


public enum ProofStatus {
    case loading
    case success
    case failure
}

struct RawProverResponse: Codable {
    let proof: String?
    let error: String?
}

import Foundation

public class Prover {
    private let notaryHost = "4f630ed.notary.pluto.dev"
    private let notaryPort = 443
    private let maxSentData = 10000
    private let maxRecvData = 10000

    public init() {}

    public func callProver(with configJSON: [String: Any]) async throws -> String? {
        print("Calling Prover with config", configJSON)
        // Convert dictionary to JSON string
        let jsonData = try JSONSerialization.data(withJSONObject: configJSON)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ProverError.invalidResponse
        }

        // Convert Swift string to C string
        guard let cConfig = jsonString.cString(using: .utf8) else {
            throw ProverError.invalidResponse
        }

//        defer { free(cConfig) } // free it later

        // Call the C function (now visible to Swift)
        guard let resultPtr = prover(cConfig) else { return nil }

        // Convert the returned C string to Swift
        let swiftResult = String(cString: resultPtr)
        return swiftResult
    }

    public func generateProof(manifest: ManifestFile, onStatusChange: ((ProofStatus) -> Void)? = nil) async throws -> String {
        // Prepare the body (or a default if nil)
        let targetBody = manifest.request.body ?? AnyCodable("")

        do {
            let base64Body = try targetBody.toBase64()
            let manifestData = try JSONEncoder().encode(manifest)
            guard let manifestDict = try JSONSerialization.jsonObject(with: manifestData) as? [String: Any] else {
                throw ProverError.invalidResponse
            }


            let config: [String: Any] = [
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

            onStatusChange?(.loading)

            do {
                // Perform Objective-C Prover Call
                let responseString = try await self.callProver(with: config)
                guard let responseData = responseString?.data(using: .utf8) else {
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

        } catch {
            print("Warning: Failed to encode body to Base64: \(error)")
            throw error
        }
    }
}

// Prover Errors
enum ProverError: Error {
    case notImplemented
    case invalidResponse
    case custom(String)
}
