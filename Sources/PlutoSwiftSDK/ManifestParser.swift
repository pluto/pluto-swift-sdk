import Foundation

// MARK: - ManifestParser
public enum ManifestParser {
    // MARK: - Public Methods
    public static func parseManifest(from jsonString: String) -> ManifestFile? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(ManifestFile.self, from: jsonData)
    }

    public static func parseManifest(from jsonData: Data) -> ManifestFile? {
        return try? JSONDecoder().decode(ManifestFile.self, from: jsonData)
    }
}

// MARK: - Error Handling
extension ManifestParser {
    public enum ParserError: Error {
        case invalidJSON
        case decodingFailed
    }
}
