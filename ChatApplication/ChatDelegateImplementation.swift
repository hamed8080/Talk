//
//  ChatDelegateImplementation.swift
//  ChatImplementation
//
//  Created by Hamed Hosseini on 2/6/21.
//

import FanapPodAsyncSDK
import FanapPodChatSDK
import Foundation
import UIKit

enum ConnectionStatus: Int {
    case connecting = 0
    case disconnected = 1
    case reconnecting = 2
    case unauthorized = 3
    case connected = 4

    var stringValue: String {
        switch self {
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .disconnected: return "disconnected"
        case .reconnecting: return "reconnectiong"
        case .unauthorized: return "un authorized"
        }
    }
}

let File_Deleted_From_Cache_Name = Notification.Name("File_Deleted_From_Cache_Name")
let CONNECT_NAME = Notification.Name("NotificationIdentifier")
let MESSAGE_NOTIFICATION_NAME = Notification.Name("MESSAGE_NOTIFICATION_NAME")
let SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME = Notification.Name("SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME")
let THREAD_EVENT_NOTIFICATION_NAME = Notification.Name("THREAD_EVENT_NOTIFICATION_NAME")

class ChatDelegateImplementation: ChatDelegate {
    private(set) static var sharedInstance = ChatDelegateImplementation()

    func createChatObject() {
        if let config = Config.getConfig(.Main) {
            if config.server == "Integeration" {
                TokenManager.shared.saveSSOToken(ssoToken: SSOTokenResponse.Result(accessToken: config.debugToken, expiresIn: Int.max, idToken: nil, refreshToken: nil, scope: nil, tokenType: nil))
            }
            TokenManager.shared.initSetIsLogin()
            let token = TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken ?? config.debugToken
            print("token is: \(token)")

            let asyncConfig = AsyncConfig(socketAddress: config.socketAddresss,
                                          serverName: config.serverName,
                                          appId: "PodChat",
                                          reconnectCount: Int.max,
                                          reconnectOnClose: true,
                                          isDebuggingLogEnabled: false)
            Chat.sharedInstance.createChatObject(config: .init(asyncConfig: asyncConfig,
                                                               token: token,
                                                               ssoHost: config.ssoHost,
                                                               platformHost: config.platformHost,
                                                               fileServer: config.fileServer,
                                                               enableCache: true,
                                                               msgTTL: 800000, // for integeration server need to be long time
                                                               isDebuggingLogEnabled: true,
                                                               enableNotificationLogObserver: true))
            Chat.sharedInstance.delegate = self
            AppState.shared.setCachedUser()
        }
    }

    func chatError(errorCode: Int, errorMessage: String, errorResult: Any?) {
        if errorCode == 21 || errorCode == 401 {
            TokenManager.shared.getNewTokenWithRefreshToken()
            AppState.shared.connectionStatus = .unauthorized
        }
        LogViewModel.addToLog(logResult: LogResult(json: "Error just happened: code\(errorCode) message:\(errorMessage) errorContent:\(errorResult.debugDescription)", receive: true))
    }

    func chatState(state: ChatState, currentUser: User?, error: ChatError?) {
        switch state {
        case .connecting:
            print("🔄 chat connecting")
            AppState.shared.connectionStatus = .connecting
        case .connected:
            print("🟡 chat connected")
            AppState.shared.connectionStatus = .connecting
        case .closed:
            print("🔴 chat Disconnect")
            AppState.shared.connectionStatus = .disconnected
        case .asyncReady:
            print("🟡 Async ready")
        case .chatReady:
            print("🟢 chat ready Called\(String(describing: currentUser))")
            AppState.shared.connectionStatus = .connected
            NotificationCenter.default.post(name: CONNECT_NAME, object: nil)
        }

        if let error = error {
            LogViewModel.addToLog(logResult: LogResult(json: "Error just happened chat state changed: code\(error.code) message:\(error.message ?? "nil") errorContent:\(error.content ?? "nil")", receive: true))
        }
    }

    func chatError(error: ChatError) {
        print(error)
    }

    func chatEvent(event: ChatEventType) {
        print(event)
        if case .system(let event) = event {
            NotificationCenter.default.post(name: SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME, object: event)
        }

        if case .thread(let event) = event {
            NotificationCenter.default.post(name: THREAD_EVENT_NOTIFICATION_NAME, object: event)
        }

        if case .message(let event) = event {
            NotificationCenter.default.post(name: MESSAGE_NOTIFICATION_NAME, object: event)
        }

        if case .file(let event) = event {
            print("file Event:\(dump(event))")
        }
    }
}
