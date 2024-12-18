import Foundation

public enum Methods: String, Codable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

public enum Mode: String, Codable {
    case TLSN = "TLSN"
    case Origo = "Origo"
}
