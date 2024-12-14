//
//  DeviceSession+.swift
//  TalkExtensions
//
//  Created by Hamed Hosseini on 12/14/24.
//

import TalkModels
import Additive

public extension DeviceSession {
    var dict: [(String, String?)] {
        var dict: [(String, String?)] = []
//        dict.append(("ManageSessions.deviceName", name ?? "General.unknown"))
        dict.append(("ManageSessions.deviceType", deviceType))
        dict.append(("ManageSessions.os", os))
        dict.append(("ManageSessions.osVersion", osVersion))
        dict.append(("ManageSessions.ip", ip))
        dict.append(("ManageSessions.lastActivity", "\(lastAccessTime?.date.timeAgoSinceDateCondense(local: Language.preferredLocale) ?? "")"))
        dict.append(("ManageSessions.location", "\(location?.name ?? "General.unknown")"))
        return dict
    }
}
