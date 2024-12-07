public struct HandshakeResponse: Codable, Sendable {
    public let algorithm: String?
    public let client: HandhsakeClient?
    public let keyFormat: String?
    public let keyId: String?
    public let expiresIn: Int?
    public let publicKey: String?
}


public struct HandhsakeClient: Codable, Sendable {
    public let accessTokenExpiryTime: Int?
    public let allowedRedirectUris: [String]?
    public let userId: Int?
    public let allowedScopes: [String]?
    public let clientId: String?
    public let allowedGrantTypes: [String]?
    public let signupEnabled: Bool?
    public let captchaEnabled: Bool?
    public let loginUrl: String?
    public let name: String?
    public let id: Int?
    public let twoFAEnabled: Bool?
    public let roles: [String]?
    public let refreshTokenExpiryTime: Int?
    public let pkceEnabled: Bool?
    public let cssEnabled: Bool?
    public let active: Bool?
}
