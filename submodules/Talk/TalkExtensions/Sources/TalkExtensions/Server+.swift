//
//  Server+.swift
//  TalkExtensions
//
//  Created by Hamed Hosseini on 1/27/26.
//

import Foundation
import TalkModels
import Spec

public extension Server {
    static let defaultMain = Server(
        server: "main",
        socket: Constants.socket.fromBase64() ?? "",
        sso: Constants.sso.fromBase64() ?? "",
        social: Constants.social.fromBase64() ?? "",
        file: Constants.file.fromBase64() ?? "",
        serverName: Constants.serverName.fromBase64() ?? "",
        talk: Constants.talkRedirect.fromBase64() ?? "",
        talkback: Constants.talkBack.fromBase64() ?? "",
        log: Constants.log.fromBase64() ?? "",
        neshan: Constants.neshan.fromBase64() ?? "",
        neshanAPI: Constants.neshanAPI.fromBase64() ?? "",
        panel: Constants.panel.fromBase64() ?? ""
    )
    
    static let defaultSandbox = Server(
        server: "sandbox",
        socket: Constants.socketSandbox.fromBase64() ?? "",
        sso: Constants.ssoSandbox.fromBase64() ?? "",
        social: Constants.socialSandbox.fromBase64() ?? "",
        file: Constants.fileSandbox.fromBase64() ?? "",
        serverName: Constants.serverNameSandbox.fromBase64() ?? "",
        talk: Constants.talkRedirectSandbox.fromBase64() ?? "",
        talkback: Constants.talkBackSandbox.fromBase64() ?? "",
        log: Constants.log.fromBase64() ?? "",
        neshan: Constants.neshan.fromBase64() ?? "",
        neshanAPI: Constants.neshanAPI.fromBase64() ?? "",
        panel: Constants.panel.fromBase64() ?? ""
    )
}
