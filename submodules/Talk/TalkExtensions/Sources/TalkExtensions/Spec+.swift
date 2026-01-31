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
    
    static func config(spec: Spec, token: String) -> ChatConfig {
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
}

public extension Server {
    
    init(socket: String, server: Server) {
        self = .init(server: server.server,
                     socket: socket,
                     sso: server.sso,
                     social: server.social,
                     file: server.file,
                     serverName: server.serverName,
                     talk: server.talk,
                     talkback: server.talkback,
                     log: server.log,
                     neshan: server.neshan,
                     neshanAPI: server.neshanAPI,
                     panel: server.panel)
    }
}

public extension Paths {
    static let defaultPaths = Paths(
        social: .init(
            listContacts: "/nzh/contact/contacts",
            addContacts: "/nzh/addContacts",
            updateContacts: "/nzh/contact/updateContact",
            removeContacts: "/nzh/removeContacts"
        ),
        podspace: .init(
            download: .init(
                thumbnail: "/api/files/{hashCode}/thumbnail",
                images: "/api/v2/images",
                files: "/api/files"),
            upload: .init(
                images: "/api/images",
                files: "/api/files",
                usergroupsFiles: "/api/usergroups/{userGroupHash}/files",
                usergroupsImages: "/api/usergroups/{userGroupHash}/images"
            )
        ),
        neshan: .init(
            reverse: "/reverse",
            search: "/search",
            routing: "/routing",
            staticImage: "/static"
        ),
        sso: .init(
            oauth: "/oauth2",
            token: "/oauth2/token",
            devices: "/oauth2/grants/devices",
            authorize: "/oauth2/authorize",
            clientId: "88413l69cd4051a039cf115ee4e073"
        ),
        talkBack: .init(
            updateImageProfile: "/api/uploadImage",
            opt: "/api/oauth2/otp",
            refreshToken: "/api/oauth2/otp/refresh",
            verify: "/api/oauth2/otp/verify",
            authorize: "/api/oauth2/otp/authorize",
            handshake: "/api/oauth2/otp/handshake"
        ),
        talk: .init(
            join: "/join?tn=",
            redirect: "talk://login"
        ),
        log: .init(talk: "/1m-http-server-test-chat"),
        panel: .init(info: "/Users/Info"))
}

public extension SubDomains {
    static let defaultSubdomains = SubDomains(core: "Y29yZS5wb2QuaXI=".fromBase64() ?? "", podspace: "cG9kc3BhY2UucG9kLmly".fromBase64() ?? "")
}

fileprivate extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
