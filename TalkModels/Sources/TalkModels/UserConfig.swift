import Chat
import ChatDTO
import ChatModels
import ChatCore

public struct UserConfig: Codable, Identifiable {
    public var id: Int? { user.id }
    public let user: User
    public let config: ChatConfig
    public let ssoToken: SSOTokenResponse

    public init(user: User, config: ChatConfig, ssoToken: SSOTokenResponse) {
        self.user = user
        self.config = config
        self.ssoToken = ssoToken
    }
}