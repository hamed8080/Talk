//
//  DeviceSession+.swift
//  TalkExtensions
//
//  Created by Hamed Hosseini on 12/14/24.
//

import TalkModels
import Additive
import Foundation

public extension DeviceSession {
    var dict: [(String, String?)] {
        var dict: [(String, String?)] = []
        dict.append(("ManageSessions.deviceName", name ?? "----"))
        dict.append(("ManageSessions.deviceType", deviceType))
        dict.append(("ManageSessions.os", os))
        dict.append(("ManageSessions.osVersion", osVersion ?? parseOSVersion()))
        dict.append(("ManageSessions.ip", clientIp ?? ip))
        dict.append(("ManageSessions.lastActivity", "\(lastAccessTime?.date.dayMonthNameYear(local: Language.preferredLocale) ?? "")"))
//        dict.append(("ManageSessions.location", "\(location?.name ?? "General.unknown")"))
        return dict
    }
    
    func parseOSVersion() -> String? {
        guard let agent = agent else { return nil }
        // Define the regex pattern
        let pattern = #"\([^;]*;.*?(\d+[_\.\d]*)"#
        
        // Create a regular expression object
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil // Invalid regex
        }
        
        // Perform the regex match
        let range = NSRange(agent.startIndex..<agent.endIndex, in: agent)
        if let match = regex.firstMatch(in: agent, options: [], range: range) {
            // Extract the captured group (the second value after the first ;)
            if let osVersionRange = Range(match.range(at: 1), in: agent) {
                var osVersion = String(agent[osVersionRange])
                // Replace underscores with dots
                osVersion = osVersion.replacingOccurrences(of: "_", with: ".")
                return osVersion
            }
        }
        return nil // No match found
    }
}
