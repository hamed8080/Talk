//
//  TalkBackSpec+.swift
//  TalkExtensions
//
//  Created by Hamed Hosseini on 1/12/26.
//

import TalkModels
import Spec

public extension TalkBackSpec {
    func toSpec() -> Spec {
        let server = Server(server: "sandbox",
                            socket: result?.socketAddress ?? "",
                            sso: String(result?.ssoUrl?.dropLast() ?? ""),
                            social: String(result?.socialUrl?.dropLast() ?? ""),
                            file: String(result?.podSpaceUrl?.dropLast() ?? ""),
                            serverName: "chat-server",
                            talk: Constants.talkSandbox.fromBase64() ?? "",
                            talkback: Constants.talkbackSandbox.fromBase64() ?? "",
                            log: Constants.logSandbox.fromBase64() ?? "",
                            neshan: Constants.neshanSandbox.fromBase64() ?? "",
                            neshanAPI: Constants.neshanAPISnadbox.fromBase64() ?? "",
                            panel: Constants.panel.fromBase64() ?? "")
        let spec = Spec(servers: [server],
                        server: server,
                        paths: .defaultPaths,
                        subDomains: .defaultSubdomains)
        return spec
    }
}
