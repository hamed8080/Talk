public enum LoginState: String, Identifiable, Hashable {
    public var id: Self { self }
    case handshake
    case login
    case verify
    case failed
    case refreshToken
    case successLoggedIn
    case verificationCodeIncorrect
}
