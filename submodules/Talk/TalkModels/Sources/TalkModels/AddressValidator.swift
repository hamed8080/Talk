//
//  AddressValidator.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 1/28/26.
//

import Foundation

public class AddressValidator {
    private var value: String
    
    public init(value: String) {
        self.value = value
    }
    
    public func isValid() -> Bool {
        isValidIP(value) || isValidWebURL(value)
    }
    
    private func isValidWebURL(_ string: String) -> Bool {
        guard let components = URLComponents(string: string),
              let scheme = components.scheme,
              ["http", "https"].contains(scheme),
              components.host != nil else {
            return false
        }
        return true
    }
    
    private func isValidIP(_ string: String) -> Bool {
        var ipv4 = in_addr()
        var ipv6 = in6_addr()

        return string.withCString { cString in
            inet_pton(AF_INET, cString, &ipv4) == 1 ||
            inet_pton(AF_INET6, cString, &ipv6) == 1
        }
    }
}
