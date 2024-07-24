public final class AppRoutes {
    public static let integeration = "https://talkotp-d.fanapsoft.ir/"
    public static let sandbox = "https://talkback.sandpod.ir/"
    public static let main = "https://talkback.pod.ir/"
    public static let joinLink = "https://talk.pod.ir/join?tn="
    public static let pckeToken = "https://accounts.pod.ir/oauth2/token"
    public static let panel = "https://panel.pod.ir/Users/Info"
    
    public static let socketAddress = "wss://msg.pod.ir/ws"
    public static let ssoHost = "https://accounts.pod.ir"
    public static let platformHost = "https://api.pod.ir/srv/core"
    public static let podspace = "https://podspace.pod.ir"
    public static let peerName = "chat-server"
    public static let map = "https://api.neshan.org/v1"
    public static let core = "core.pod.ir"
    public static let ssoAuthorizeURL = "\(ssoHost)/oauth2/authorize"
    public static let ssoTokenURL = "\(ssoHost)/oauth2/token"
    public static let chatLogger = "http://10.56.34.61:8080/1m-http-server-test-chat"

    public let base: String
    public let api: String
    public let oauth: String
    public let otp: String
    public let handshake: String
    public let authorize: String
    public let verify: String
    public let refreshToken: String
    public let updateProfileImage: String

    public init(serverType: ServerTypes) {
        if serverType == .integration {
            self.base = AppRoutes.integeration
        } else if serverType == .sandbox {
            self.base = AppRoutes.sandbox
        } else {
            self.base = AppRoutes.main
        }
        api = "api/"
        oauth = "oauth2/"
        otp = base + api + oauth + "otp/"
        handshake = otp + "handshake"
        authorize = otp + "authorize"
        verify = otp + "verify"
        refreshToken = otp + "refresh"
        updateProfileImage = base + api + "/uploadImage"
    }
}
