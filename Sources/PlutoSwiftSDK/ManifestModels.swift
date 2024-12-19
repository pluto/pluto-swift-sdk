import Foundation

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

public class ManifestFileRequest: Codable {
    public var method: Methods
    public var url: String
    public var headers: [String: String]
    public var body: String?
    public var vars: [String: ManifestVars]?
    public var extra: ManifestFileRequest?

    public init(method: Methods, url: String, headers: [String: String], body: String? = nil,
                vars: [String: ManifestVars]? = nil, extra: ManifestFileRequest? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.vars = vars
        self.extra = extra
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
