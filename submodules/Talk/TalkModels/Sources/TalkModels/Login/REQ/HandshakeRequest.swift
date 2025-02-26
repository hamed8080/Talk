public struct HandshakeRequest: Encodable, Sendable {
    public let deviceName: String
    public let deviceOs: String
    public let deviceOsVersion: String
    public let deviceType: String
    public let deviceUID: String

    public init(deviceName: String, deviceOs: String, deviceOsVersion: String, deviceType: String, deviceUID: String) {
        self.deviceName = deviceName
        self.deviceOs = deviceOs
        self.deviceOsVersion = deviceOsVersion
        self.deviceType = deviceType
        self.deviceUID = deviceUID
    }
}
