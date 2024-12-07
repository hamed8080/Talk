public struct SSOTokenResponse: Codable, Sendable {
    public let accessToken: String?
    public let expiresIn: Int
    public let refreshToken: String?
    public let scope: String?
    public let tokenType: String?
    public let idToken: String?
    public let deviceUID: String?
    /// Only when saving for the first time, we should manullay save keyId in the UserDefault Storage.
    public var keyId: String?

    // Create by the application to refresh token later
    public var codeVerifier: String?

    public init(accessToken: String? = nil, expiresIn: Int, idToken: String? = nil, refreshToken: String? = nil, scope: String? = nil, tokenType: String? = nil, deviceUID: String? = nil, codeVerifier: String? = nil) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.scope = scope
        self.tokenType = tokenType
        self.deviceUID = deviceUID
        self.codeVerifier = codeVerifier
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case idToken = "id_token"
        case deviceUID = "device_uid"
        case scope = "scope"

        /// Only when saving for the first time, we should manullay save keyId in the UserDefault Storage.
        case keyId = "keyId"
        /// Create By the app
        case codeVerifier = "codeVerifier"
    }
}
