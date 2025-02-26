import Chat
public enum ConnectionStatus: Int, Sendable {
    case connecting = 0
    case disconnected = 1
    case reconnecting = 2
    case unauthorized = 3
    case connected = 4

    public var stringValue: String {
        switch self {
        case .connecting: return "ConnectionStatus.connecting"
        case .connected: return "ConnectionStatus.connected"
        case .disconnected: return "ConnectionStatus.disconnected"
        case .reconnecting: return "ConnectionStatus.reconnecting"
        case .unauthorized: return "ConnectionStatus.unauthorized"
        }
    }
}
