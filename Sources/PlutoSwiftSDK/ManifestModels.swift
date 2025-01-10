import Foundation

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            var converted = [String: Any]()
            for (k, v) in dictValue { converted[k] = v.value }
            value = converted
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable: cannot decode value"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            let encodedDict = dictValue.mapValues { AnyCodable($0) }
            try container.encode(encodedDict)
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable: cannot encode value"
                )
            )
        }
    }

    public func toBase64() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        return jsonData.base64EncodedString()
    }
}


public struct ManifestVars: Codable {
    public var type: String?
    public var regex: String?
    public var length: Int?
    
    public init(type: String? = nil, regex: String? = nil, length: Int? = nil) {
        self.type = type
        self.regex = regex
        self.length = length
    }
}

public struct ManifestFileRequest: Codable {
    public var method: Methods
    public var url: String
    public var headers: [String: String]
    public var body: AnyCodable?
    public var vars: [String: ManifestVars]?
    public var extra: ManifestFileRequestExtra?

    public init(
        method: Methods,
        url: String,
        headers: [String: String],
        body: AnyCodable? = nil,
        vars: [String: ManifestVars]? = nil,
        extra: ManifestFileRequestExtra? = nil
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.vars = vars
        self.extra = extra
    }
}

public struct ManifestFileRequestExtra: Codable {
    public var method: Methods?
    public var url: String?
    public var headers: [String: String]?
    public var body: AnyCodable?
    public var vars: [String: ManifestVars]?

    public init(
        method: Methods? = nil,
        url: String? = nil,
        headers: [String: String]? = nil,
        body: AnyCodable? = nil,
        vars: [String: ManifestVars]? = nil
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.vars = vars
    }
}


public class ManifestFileResponse: Codable {
    public class ResponseBody: Codable {
        public var json: [String]

        public init(json: [String]) {
            self.json = json
        }
    }
    
    public var status: String
    public var headers: [String: String]
    public var body: ResponseBody

    public init(status: String, headers: [String: String], body: ResponseBody) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}

public struct ManifestFile: Codable {
    public var manifestVersion: String
    public var id: String
    public var title: String
    public var description: String
    public var prepareUrl: String?
    public var mode: Mode?
    public var request: ManifestFileRequest
    public var response: ManifestFileResponse

    public init(manifestVersion: String, id: String, title: String, description: String,
                prepareUrl: String? = nil, mode: Mode? = nil,
                request: ManifestFileRequest, response: ManifestFileResponse) {
        self.manifestVersion = manifestVersion
        self.id = id
        self.title = title
        self.description = description
        self.prepareUrl = prepareUrl
        self.mode = mode
        self.request = request
        self.response = response
    }
}
