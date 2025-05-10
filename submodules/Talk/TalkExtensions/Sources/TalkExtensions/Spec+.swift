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
    static func empty() -> Spec {
        Spec(empty: true)
    }
    
    init(empty: Bool) {
        self = Spec(
            servers: [],
            server: .init(
                server: "",
                socket: "",
                sso: "",
                social: "",
                file: "",
                serverName: "",
                talk: "",
                talkback: "",
                log: "",
                neshan: "",
                neshanAPI: "",
                panel: ""
            ),
            paths: .init(
                social: .init(
                    listContacts: "",
                    addContacts: "",
                    updateContacts: "",
                    removeContacts: ""),
                podspace: .init(
                    download: .init(
                        thumbnail: "",
                        images: "", files: ""),
                    upload: .init(
                        images: "", files: "",
                        usergroupsFiles: "",
                        usergroupsImages: "")),
                neshan: .init(
                    reverse: "",
                    search: "",
                    routing: "",
                    staticImage: ""),
                sso: .init(
                    oauth: "",
                    token: "",
                    devices: "",
                    authorize: "",
                    clientId: ""),
                talkBack: .init(
                    updateImageProfile: "",
                    opt: "",
                    refreshToken: "",
                    verify: "",
                    authorize: "",
                    handshake: ""),
                talk: .init(
                    join: "",
                    redirect: ""),
                log: .init(talk: ""),
                panel: .init(info: "")),
            subDomains: .init(core: "", podspace: ""))
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
        var req = URLRequest(url: url)
        req.method = .get
        let (data, response) = await try URLSession.shared.data(req)
        let spec = try JSONDecoder.instance.decode(Spec.self, from: data)
        storeSpec(spec)        
        return spec
    }
}
