public final class AppRoutes {
    public static let integeration = "https://talkotp-d.fanapsoft.ir/"
    public static let sandbox = "https://talkotp-s.fanapsoft.ir/"
    public static let main = "https://talkback.pod.ir/"
    public static let joinLink = "https://talk.pod.ir/join?tn="

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
