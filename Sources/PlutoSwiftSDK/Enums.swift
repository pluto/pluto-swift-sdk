import Foundation

// MARK: - HTTP Methods
public enum Methods: String, Codable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
}

// MARK: - Proof Generation Mode
public enum Mode: String, Codable {
    case Origo = "Origo"
    case TEE = "TEE"
    case Proxy = "Proxy"
    case TLSN = "TLSN"

    public var rawValue: String {
        switch self {
        case .Origo: return "Origo"
        case .TEE: return "TEE"
        case .Proxy: return "Proxy"
        case .TLSN: return "TLSN"
        }
    }
}
