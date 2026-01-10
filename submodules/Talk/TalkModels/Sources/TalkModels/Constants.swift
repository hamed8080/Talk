//
//  Constants.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 1/10/26.
//

import Foundation

public struct Constants: Sendable {
    nonisolated(unsafe) public static let version = "1.101"
    
    /// Bundle production URL
    /// https://github.com/hamed8080/bundle/archive/refs/tags/v1.101.zip
    nonisolated(unsafe) public static let bundleURL = "aHR0cHM6Ly9naXRodWIuY29tL2hhbWVkODA4MC9idW5kbGUvYXJjaGl2ZS9yZWZzL3RhZ3MvdjEuMTAxLnppcA=="
    
    /// Bundle local URL
    /// https://podspace.pod.ir/api/files/2RVR8Z2T8998X27N
    nonisolated(unsafe) public static let bundleLocalURL = "aHR0cHM6Ly9wb2RzcGFjZS5wb2QuaXIvYXBpL2ZpbGVzLzJSVlI4WjJUODk5OFgyN04="
    
    /// Spec production URL
    /// https://raw.githubusercontent.com/hamed8080/bundle/v1.101/Spec.json
    nonisolated(unsafe) public static let specProdURL = "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2hhbWVkODA4MC9idW5kbGUvdjEuMTAxL1NwZWMuanNvbg=="
    
    /// Spec local URL
    /// https://podspace.pod.ir/api/files/HBTN89DXDKI1713J
    nonisolated(unsafe) public static let specLocalURL = "aHR0cHM6Ly9wb2RzcGFjZS5wb2QuaXIvYXBpL2ZpbGVzL0hCVE44OURYREtJMTcxM0o="
}
