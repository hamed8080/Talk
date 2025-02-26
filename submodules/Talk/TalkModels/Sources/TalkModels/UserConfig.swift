import Chat

public struct UserConfig: Codable, Identifiable, Sendable {
    public var id: Int? { user.id }
    public let user: User
    public let config: ChatConfig
    public var ssoToken: SSOTokenResponse

    public init(user: User, config: ChatConfig, ssoToken: SSOTokenResponse) {
        self.user = user
        self.config = config
        self.ssoToken = ssoToken
    }

    mutating public func updateSSOToken(_ ssoToken: SSOTokenResponse) {
        self.ssoToken = ssoToken
    }
}
