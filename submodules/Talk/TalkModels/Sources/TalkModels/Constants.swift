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
    
    /// TalkBakc config URL
    /// https://talkback.sandpod.ir/api/talk/configs
    nonisolated(unsafe) public static let specTalkBackURL = "aHR0cHM6Ly90YWxrYmFjay5zYW5kcG9kLmlyL2FwaS90YWxrL2NvbmZpZ3M="
    
    /// Talk sandbox talk
    /// https://talk.pod.ir
    nonisolated(unsafe) public static let talkSandbox = "aHR0cHM6Ly90YWxrLnBvZC5pcg=="
    
    /// TalkBack sandbox URL
    /// https://talkback.sandpod.ir
    nonisolated(unsafe) public static let talkbackSandbox = "aHR0cHM6Ly90YWxrYmFjay5zYW5kcG9kLmly"
    
    /// Log sandbox URL
    /// http://10.56.34.61:8080
    nonisolated(unsafe) public static let logSandbox = "aHR0cDovLzEwLjU2LjM0LjYxOjgwODA="
    
    /// Nesahn sandbox URL
    /// https://maps.neshan.org
    nonisolated(unsafe) public static let neshanSandbox = "aHR0cHM6Ly9tYXBzLm5lc2hhbi5vcmc="
    
    /// Neshan API sandbox URL
    /// https://api.neshan.org/v1
    nonisolated(unsafe) public static let neshanAPISnadbox = "aHR0cHM6Ly9hcGkubmVzaGFuLm9yZy92MQ=="
    
    /// Panel sandbox URL
    /// https://panel.pod.ir
    nonisolated(unsafe) public static let panel = "aHR0cHM6Ly9wYW5lbC5wb2QuaXI="
}
