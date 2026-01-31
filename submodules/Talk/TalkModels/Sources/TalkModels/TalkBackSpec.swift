//
//  TalkBackSpec.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 1/12/26.
//

import Foundation

public struct TalkBackSpec: Codable {
    public let result: TalkBackResult?
    public let uniqueId: String?
    public let status: Int?
    
    enum CodingKeys: String, CodingKey {
        case result = "result"
        case uniqueId = "uniqueId"
        case status = "status"
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.result = try container.decodeIfPresent(TalkBackResult.self, forKey: .result)
        self.uniqueId = try container.decodeIfPresent(String.self, forKey: .uniqueId)
        self.status = try container.decodeIfPresent(Int.self, forKey: .status)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.result, forKey: .result)
        try container.encodeIfPresent(self.uniqueId, forKey: .uniqueId)
        try container.encodeIfPresent(self.status, forKey: .status)
    }
}

public struct TalkBackResult: Codable {
    public let socketAddress: String?
    public let podSpaceUrl: String?
    public let platformHost: String?
    public let ssoUrl: String?
    public let `protocol`: String?
    public let uniqueId: String?
    
    public init(socketAddress: String? = nil,
                podSpaceUrl: String? = nil,
                platformHost: String? = nil,
                ssoUrl: String? = nil,
                `protocol`: String? = nil,
                uniqueId: String? = nil) {
        self.socketAddress = socketAddress
        self.podSpaceUrl = podSpaceUrl
        self.platformHost = platformHost
        self.ssoUrl = ssoUrl
        self.`protocol` = `protocol`
        self.uniqueId = uniqueId
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.socketAddress = try container.decodeIfPresent(String.self, forKey: .socketAddress)
        self.podSpaceUrl = try container.decodeIfPresent(String.self, forKey: .podSpaceUrl)
        self.platformHost = try container.decodeIfPresent(String.self, forKey: .platformHost)
        self.ssoUrl = try container.decodeIfPresent(String.self, forKey: .ssoUrl)
        self.protocol = try container.decodeIfPresent(String.self, forKey: .protocol)
        self.uniqueId = try container.decodeIfPresent(String.self, forKey: .uniqueId)
    }
    
    enum CodingKeys: String, CodingKey {
        case socketAddress = "socketAddress"
        case podSpaceUrl = "podSpaceUrl"
        case platformHost = "platformHost"
        case ssoUrl = "ssoUrl"
        case `protocol` = "protocol"
        case uniqueId = "uniqueId"
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.socketAddress, forKey: .socketAddress)
        try container.encodeIfPresent(self.podSpaceUrl, forKey: .podSpaceUrl)
        try container.encodeIfPresent(self.platformHost, forKey: .platformHost)
        try container.encodeIfPresent(self.platformHost, forKey: .platformHost)
        try container.encodeIfPresent(self.ssoUrl, forKey: .ssoUrl)
        try container.encodeIfPresent(self.protocol, forKey: .protocol)
        try container.encodeIfPresent(self.uniqueId, forKey: .uniqueId)
    }
}
