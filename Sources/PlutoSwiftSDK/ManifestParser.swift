import Foundation

public struct ManifestParser {
    public static func parseManifest(from jsonString: String) -> ManifestFile? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Error: Invalid JSON string")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let manifest = try decoder.decode(ManifestFile.self, from: jsonData)
            return manifest
        } catch {
            print("Error decoding manifest: \(error.localizedDescription)")
            return nil
        }
    }
}
