import Foundation

public struct AuthorizeResponse: Codable, Sendable {
    public let expiresIn: Int?
    public let identity: String?
    public let type: String?
    public let userId: String?
    public let codeLength: Int?
    public let sentBefore: Bool?
    public let error: String?
    public var errorMessage: ErrorMessage?
    private var internalErrorMessage: String?

    enum CodingKeys: String, CodingKey {
        case expiresIn = "expires_in"
        case identity = "identity"
        case type = "type"
        case userId = "user_id"
        case codeLength = "codeLength"
        case sentBefore = "sent_before"
        case error = "error"
        case internalErrorMessage = "message"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)
        self.identity = try container.decodeIfPresent(String.self, forKey: .identity)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
        self.codeLength = try container.decodeIfPresent(Int.self, forKey: .codeLength)
        self.sentBefore = try container.decodeIfPresent(Bool.self, forKey: .sentBefore)
        self.error = try container.decodeIfPresent(String.self, forKey: .error)

        if let data = try container.decodeIfPresent(String.self, forKey: .internalErrorMessage)?.data(using: .utf8) {
            self.errorMessage = try JSONDecoder().decode(ErrorMessage.self, from: data)
        }
    }
}

public struct ErrorMessage: Codable, Sendable {
    public let error: String?
    public let description: String?
    public let unlockInSec: Int?

    enum CodingKeys: String, CodingKey {
        case error = "error"
        case description = "error_description"
        case unlockInSec = "unlocks_in_sec"
    }
}
