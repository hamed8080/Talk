import Foundation
import Chat

public enum StrictThreadTypeCreation: Int, Sendable {
    case p2p = 0
    case privateGroup = 1
    case publicGroup = 2
    case privateChannel = 8
    case publicChannel = 64
    case selfThread = 128

    public var threadType: ThreadTypes {
        switch self {
        case .p2p:
            return .normal
        case .privateGroup:
            return .ownerGroup
        case .publicGroup:
            return .publicGroup
        case .privateChannel:
            return .channel
        case .publicChannel:
            return .publicChannel
        case .selfThread:
            return .selfThread
        }
    }

    public var toPublicType: StrictThreadTypeCreation? {
        switch self {
        case .p2p:
            return nil
        case .privateGroup:
            return .publicGroup
        case .publicGroup:
            return .publicGroup
        case .privateChannel:
            return .publicChannel
        case .publicChannel:
            return .publicChannel
        case .selfThread:
            return nil
        }
    }

    public var isChannelType: Bool {
        return self == .publicChannel || self == .privateChannel
    }

    public var isGroupType: Bool {
        return self == .privateGroup || self == .publicGroup
    }
}
