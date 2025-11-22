//
//  Spec+.swift
//  TalkExtensions
//
//  Created by Hamed Hosseini on 3/3/25.
//

import Foundation
import Chat
import TalkModels
import Logger

public extension Spec {
    
    init(empty: Bool) {
        self = Spec.empty
    }
    
    static func config(spec: Spec, token: String, selectedServerType: ServerTypes) -> ChatConfig {
        let callConfig = CallConfigBuilder()
            .callTimeout(20)
            .targetVideoWidth(640)
            .targetVideoHeight(480)
            .maxActiveVideoSessions(2)
            .targetFPS(15)
            .build()
        let asyncLoggerConfig = LoggerConfig(spec: spec,
                                             prefix: "ASYNC_SDK",
                                             logServerMethod: "PUT",
                                             persistLogsOnServer: true,
                                             isDebuggingLogEnabled: true,
                                             sendLogInterval: 5 * 60,
                                             logServerRequestheaders: ["Authorization": "Basic Y2hhdDpjaGF0MTIz", "Content-Type": "application/json"])
        let chatLoggerConfig = LoggerConfig(spec: spec,
                                            prefix: "CHAT_SDK",
                                            logServerMethod: "PUT",
                                            persistLogsOnServer: true,
                                            isDebuggingLogEnabled: true,
                                            sendLogInterval: 5 * 60,
                                            logServerRequestheaders: ["Authorization": "Basic Y2hhdDpjaGF0MTIz", "Content-Type": "application/json"])
        let asyncConfig = try! AsyncConfigBuilder(spec: spec)
            .reconnectCount(Int.max)
            .reconnectOnClose(true)
            .appId("PodChat")
            .peerName(spec.server.serverName)
            .loggerConfig(asyncLoggerConfig)
            .build()
        let chatConfig = ChatConfigBuilder(spec: spec, asyncConfig)
            .callConfig(callConfig)
            .token(token)
            .enableCache(true)
            .msgTTL(800_000) // for integeration server need to be long time
            .persistLogsOnServer(true)
            .appGroup(AppGroup.group)
            .loggerConfig(chatLoggerConfig)
            .mapApiKey("8b77db18704aa646ee5aaea13e7370f4f88b9e8c")
            .typeCodes([.init(typeCode: "default", ownerId: nil)])
            .build()
        return chatConfig
    }
    
    fileprivate static let key = "SPEC_KEY"
    static func cachedSpec() -> Spec? {
        return UserDefaults.standard.codableValue(forKey: Spec.key)
    }
    
    static func storeSpec(_ spec: Spec) {
        UserDefaults.standard.setValue(codable: spec, forKey: Spec.key)
    }
    
    static func dl() async throws -> Spec {
        // https://raw.githubusercontent.com/hamed8080/bundle/v1.0/Spec.json
        guard let string = "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2hhbWVkODA4MC9idW5kbGUvdjEuMC9TcGVjLmpzb24=".fromBase64(),
        let url = URL(string: string)
        else { throw URLError.init(.badURL) }
        var req = URLRequest(url: url, timeoutInterval: 10.0)
        req.method = .get
        let (data, response) = await try URLSession.shared.data(req)
        let spec = try JSONDecoder.instance.decode(Spec.self, from: data)
        storeSpec(spec)        
        return spec
    }
}

extension Spec {
    static func serverType(config: ChatConfig?) -> ServerTypes? {
        if config?.spec.server.server == ServerTypes.main.rawValue {
            return .main
        } else if config?.spec.server.server == ServerTypes.sandbox.rawValue {
            return .sandbox
        } else if config?.spec.server.server == ServerTypes.integration.rawValue {
            return .integration
        } else {
            return nil
        }
    }
}
