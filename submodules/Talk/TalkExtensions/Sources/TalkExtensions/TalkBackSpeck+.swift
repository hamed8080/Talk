//
//  TalkBackSpec+.swift
//  TalkExtensions
//
//  Created by Hamed Hosseini on 1/12/26.
//

import TalkModels
import Spec

public extension TalkBackSpec {
    func toSpec(isSandbox: Bool) -> Spec {
        let server = Server(server: isSandbox ? ServerTypes.sandbox.rawValue : ServerTypes.main.rawValue,
                            socket: result?.socketAddress ?? "",
                            sso: String(result?.ssoUrl?.dropLast() ?? ""),
                            social: String(result?.platformHost?.dropLast() ?? ""),
                            file: String(result?.podSpaceUrl?.dropLast() ?? ""),
                            serverName: "chat-server",
                            talk: isSandbox ? Constants.talkRedirectSandbox.fromBase64() ?? "" : Constants.talkRedirect.fromBase64() ?? "",
                            talkback: isSandbox ? Constants.talkBackSandbox.fromBase64() ?? "" : Constants.talkBack.fromBase64() ?? "" ,
                            log: Constants.log.fromBase64() ?? "",
                            neshan: Constants.neshan.fromBase64() ?? "",
                            neshanAPI: Constants.neshanAPI.fromBase64() ?? "",
                            panel: Constants.panel.fromBase64() ?? "")
        let spec = Spec(servers: [server],
                        server: server,
                        paths: .defaultPaths,
                        subDomains: .defaultSubdomains)
        return spec
    }
}
