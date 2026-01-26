//
//  Constants.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 1/10/26.
//

import Foundation

public struct Constants: Sendable {
    nonisolated(unsafe) public static let version = "1.102"
    
    /// TalkBack sandbox URL
    /// https://talkback2.pod.ir
    nonisolated(unsafe) public static let talkBack = "aHR0cHM6Ly90YWxrYmFjazIucG9kLmly"
    
    /// TalkBack sandbox URL
    /// https://talkback.sandpod.ir
    nonisolated(unsafe) public static let talkBackSandbox = "aHR0cHM6Ly90YWxrYmFjay5zYW5kcG9kLmly"
    
    /// Path of the configs in which it will be appended to base url of the talk back
    /// /api/talk/configs?platform=IOS
    /// https:://talkback.sandpod.ir/api/talk/configs?platform=IOS
    nonisolated(unsafe) public static let talkBackConfigsPath = "L2FwaS90YWxrL2NvbmZpZ3M/cGxhdGZvcm09SU9T"
    
    /// Bundle local URL
    /// v1.102
    /// https://podspace.pod.ir/api/files/B9ORLAYJAGV44T29
    nonisolated(unsafe) public static let bundleURL = "aHR0cHM6Ly9wb2RzcGFjZS5wb2QuaXIvYXBpL2ZpbGVzL0I5T1JMQVlKQUdWNDRUMjk="
    
    /// TalkBack main 1 config URL
    /// https://talkback2.pod.ir/api/talk/auth/configs?platform=IOS
    nonisolated(unsafe) public static let talkBackProductionSpecURL = "aHR0cHM6Ly90YWxrYmFjazIucG9kLmlyL2FwaS90YWxrL2F1dGgvY29uZmlncz9wbGF0Zm9ybT1JT1M="
    
    /// TalkBack main 2 config URL
    /// https://talk.pod.ir/api/talk/auth/configs?platform=IOS
    nonisolated(unsafe) public static let talkBackSecondSpecURL = "aHR0cHM6Ly90YWxrLnBvZC5pci9hcGkvdGFsay9hdXRoL2NvbmZpZ3M/cGxhdGZvcm09SU9T"
    
    /// TalkBack sandbox 1 config URL
    /// https://talkback2.sandpod.ir/api/talk/configs?platform=IOS
    nonisolated(unsafe) public static let talkBackSandboxSpecURL = "aHR0cHM6Ly90YWxrYmFjazIuc2FuZHBvZC5pci9hcGkvdGFsay9jb25maWdzP3BsYXRmb3JtPUlPUw=="
    
    /// TalkBack sandbox 2 config URL
    /// https://talkback.sandpod.ir/api/talk/configs?platform=IOS
    nonisolated(unsafe) public static let talkBackSecondSandboxSpecURL = "aHR0cHM6Ly90YWxrYmFjay5zYW5kcG9kLmlyL2FwaS90YWxrL2NvbmZpZ3M/cGxhdGZvcm09SU9T"
    
    /// Podspace public Spec URL
    /// https://podspace.pod.ir/api/files/CYRTOUEOQPC6NWGJ
    nonisolated(unsafe) public static let podspacePublicSpec = "aHR0cHM6Ly9wb2RzcGFjZS5wb2QuaXIvYXBpL2ZpbGVzL0NZUlRPVUVPUVBDNk5XR0o="

    /// Talk main redirect
    /// https://talk.pod.ir
    nonisolated(unsafe) public static let talkRedirect = "aHR0cHM6Ly90YWxrLnBvZC5pcg=="
    
    /// Talk sandpod redirect
    /// https://chat.sandpod.ir
    nonisolated(unsafe) public static let talkRedirectSandbox = "aHR0cHM6Ly9jaGF0LnNhbmRwb2QuaXI="
    
    /// Log URL
    /// http://10.56.34.61:8080
    nonisolated(unsafe) public static let log = "aHR0cDovLzEwLjU2LjM0LjYxOjgwODA="
    
    /// Nesahn URL
    /// https://maps.neshan.org
    nonisolated(unsafe) public static let neshan = "aHR0cHM6Ly9tYXBzLm5lc2hhbi5vcmc="
    
    /// Neshan API URL
    /// https://api.neshan.org/v1
    nonisolated(unsafe) public static let neshanAPI = "aHR0cHM6Ly9hcGkubmVzaGFuLm9yZy92MQ=="
    
    /// Panel URL
    /// https://panel.pod.ir
    nonisolated(unsafe) public static let panel = "aHR0cHM6Ly9wYW5lbC5wb2QuaXI="
    
    /// Socket main address
    /// wss://msg1.pod.ir/ws
    nonisolated(unsafe) public static let socket = "d3NzOi8vbXNnMS5wb2QuaXIvd3M="
    
    /// Socket sandbox address
    /// wss://api.sandpod.ir/ws
    nonisolated(unsafe) public static let socketSandbox = "d3NzOi8vYXBpLnNhbmRwb2QuaXIvd3M="
    
    /// File server main address
    /// https://podspace.pod.ir
    nonisolated(unsafe) public static let file = "aHR0cHM6Ly9wb2RzcGFjZS5wb2QuaXI="
    
    /// File server sandbox address
    /// http://podspace.sandpod.ir:8080
    nonisolated(unsafe) public static let fileSandbox = "aHR0cDovL3BvZHNwYWNlLnNhbmRwb2QuaXI6ODA4MA=="
    
    /// SSO main address
    /// https://accounts.pod.ir
    nonisolated(unsafe) public static let sso = "aHR0cHM6Ly9hY2NvdW50cy5wb2QuaXI="
    
    /// SSO sandbox address
    /// https://accounts.pod.ir
    nonisolated(unsafe) public static let ssoSandbox = "aHR0cHM6Ly9hY2NvdW50cy5wb2QuaXI="
    
    /// Social address
    /// https://api.pod.ir/srv/core
    nonisolated(unsafe) public static let social = "aHR0cHM6Ly9hcGkucG9kLmlyL3Nydi9jb3Jl"
    
    /// Social sandbox address
    /// https://sandbox.sandpod.ir/srv/basic-platform
    nonisolated(unsafe) public static let socialSandbox = "aHR0cHM6Ly9zYW5kYm94LnNhbmRwb2QuaXIvc3J2L2Jhc2ljLXBsYXRmb3Jt"
    
    /// Server Name main
    /// chat-server
    nonisolated(unsafe) public static let serverName = "Y2hhdC1zZXJ2ZXI="
    
    /// Server Name sandbox
    /// chat-server
    nonisolated(unsafe) public static let serverNameSandbox = "Y2hhdC1zZXJ2ZXI="
}
