import Foundation

public class PlutoSwiftSDK {
    public static func generateProof(config: String) -> String {
        return Prover.generateProof(config: config)
    }
}
