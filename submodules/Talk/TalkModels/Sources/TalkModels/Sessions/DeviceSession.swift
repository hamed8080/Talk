//
//  DeviceSession.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation

public struct DeviceSession: Decodable, Sendable, Identifiable {
    public let id: Int
    public let uid: String?
    public let agent: String?
    public let ip: String?
    public let clientIp: String?
    public let language: String?
    public let os: String?
    public let osVersion: String?
    public let browser: String?
    public let browserVersion: String?
    public let deviceType: String?
    public let current: Bool?
    public let lastAccessTime: UInt?
    public let name: String?
    public let location: DeviceSessionLocation?
    public let appVersion: String?
    public let appName: String?
    public let activeUser: SSOActiveUser?
    
    public init(
        id: Int, uid: String?, agent: String?, ip: String?, clientIp: String?, language: String?,
        os: String?, osVersion: String?, browser: String?,
        browserVersion: String?, deviceType: String?, current: Bool?,
        lastAccessTime: UInt?, name: String?, location: DeviceSessionLocation?,
        appVersion: String?, appName: String?, activeUser: SSOActiveUser?
    ) {
        self.id = id
        self.uid = uid
        self.agent = agent
        self.ip = ip
        self.clientIp = clientIp
        self.language = language
        self.os = os
        self.osVersion = osVersion
        self.browser = browser
        self.browserVersion = browserVersion
        self.deviceType = deviceType
        self.current = current
        self.lastAccessTime = lastAccessTime
        self.name = name
        self.location = location
        self.appVersion = appVersion
        self.appName = appName
        self.activeUser = activeUser
    }
}

public struct DeviceSessionLocation: Decodable, Sendable {
    public let lat: Double?
    public let lon: Double?
    public let countryCode: String?
    public let name: String?
    
    public init(lat: Double?, lon: Double?, countryCode: String?, name: String?)
    {
        self.lat = lat
        self.lon = lon
        self.countryCode = countryCode
        self.name = name
    }
}

public struct SSOActiveUser: Decodable, Sendable {
    public let preferred_username: String?
    public let given_name: String?
    public let family_name: String?
    public let id: Int?
    public let picture: String?
    public let phone_number_verified: Bool?
    public let email_verified: Bool?
    public let nationalcode_verified: Bool?
    
    public init(
        preferred_username: String?, given_name: String?, family_name: String?,
        id: Int?, picture: String?, phone_number_verified: Bool?,
        email_verified: Bool?, nationalcode_verified: Bool?
    ) {
        self.preferred_username = preferred_username
        self.given_name = given_name
        self.family_name = family_name
        self.id = id
        self.picture = picture
        self.phone_number_verified = phone_number_verified
        self.email_verified = email_verified
        self.nationalcode_verified = nationalcode_verified
    }
}

public struct SSODevicesList: Decodable, Sendable {
    public let total: Int
    public let size: Int
    public let offset: Int
    public let devices: [DeviceSession]
    
    public init(total: Int, size: Int, offset: Int, devices: [DeviceSession]) {
        self.total = total
        self.size = size
        self.offset = offset
        self.devices = devices
    }
}
