//
//  ChatDelegateImplementation.swift
//  ChatImplementation
//
//  Created by Hamed Hosseini on 2/6/21.
//

import Chat
import Foundation
import Logger
import TalkModels
import TalkViewModels
import OSLog
import SwiftUI

final class ChatDelegateImplementation: ChatDelegate {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Talk-App")
    private(set) static var sharedInstance = ChatDelegateImplementation()

    @MainActor
    func createChatObject() {
        if let userConfig = UserConfigManagerVM.instance.currentUserConfig, let userId = userConfig.id {
            UserConfigManagerVM.instance.createChatObjectAndConnect(userId: userId, config: userConfig.config, delegate: self)
            TokenManager.shared.initSetIsLogin()
        }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in}
    }

    func chatState(state: ChatState, currentUser: User?, error _: ChatError?) {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                NotificationCenter.connect.post(name: .connect, object: state)
                switch state {
                case .connecting:
                    self.log("🔄 chat connecting")
                    AppState.shared.connectionStatus = .connecting
                case .connected:
                    self.log("🟡 chat connected")
                    AppState.shared.connectionStatus = .connecting
                case .closed:
                    self.log("🔴 chat Disconnect")
                    AppState.shared.connectionStatus = .disconnected
                case .asyncReady:
                    self.log("🟡 Async ready")
                case .chatReady:
                    self.log("🟢 chat ready Called\(String(describing: currentUser))")
                    /// Clear old requests in queue when reconnect again
                    RequestsManager.shared.clear()
                    AppState.shared.connectionStatus = .connected
                case .uninitialized:
                    self.log("Chat object is not initialized.")
                }
            }
        }
    }

    func chatEvent(event: ChatEventType) {
        let copy = event
        Task { @MainActor in
            NotificationCenter.post(event: copy)
            switch event {
            case let .system(systemEventTypes):
                self.onSystemEvent(systemEventTypes)
            case let .user(userEventTypes):
                self.onUserEvent(userEventTypes)
            default:
                break
            }
        }
    }

    @MainActor
    private func onUserEvent(_ event: UserEventTypes) {
        switch event {
        case let .user(response):
            if let user = response.result {
                UserConfigManagerVM.instance.onUser(user)
                AppState.shared.updateUserCache()
            }
        default:
            break
        }
    }

    private func onSystemEvent(_ event: SystemEventTypes) {
        switch event {
        case let .error(chatResponse):
            onError(chatResponse)
        default:
            break
        }
    }

    private func onError(_ response: ChatResponse<Sendable>) {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                NotificationCenter.error.post(name: .error, object: response)
            }
        }
        guard let error = response.error else { return }
        if error.code == 21 {
            let log = Log(prefix: "TALK_APP", time: .now, message: "Start a new Task in onError with error 21", level: .error, type: .sent, userInfo: nil)
            onLog(log: log)
            tryRefreshToken()
        } else {
            if response.isPresentable {
                Task { @MainActor in
                    AppState.shared.animateAndShowError(error)
                }
            }
        }
    }

    private func tryRefreshToken() {
        Task { @MainActor in
            do {
                try await TokenManager.shared.getNewTokenWithRefreshToken()
                // If the chat was connected and we refresh token during 10 seconds period successfully, it means we are still connected to the server so the sate is connected even after refreshing the token. However, if we weren't connected during refresh token it means that we weren't connected so we will move to the connecting stage.
                AppState.shared.connectionStatus = AppState.shared.connectionStatus == .connected ? .connected : .connecting
            } catch {
                if let error = error as? AppErrors, error == AppErrors.revokedToken {
                    await self.logout()
                }
            }
        }
    }
    
    @MainActor
    func logout() async {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.user.logOut()
        }
        TokenManager.shared.clearToken()
        UserConfigManagerVM.instance.logout(delegate:  self)
        await AppState.shared.objectsContainer.reset()
    }

    func onLog(log: Log) {
#if DEBUG
        Task { @MainActor in
            NotificationCenter.logs.post(name: .logs, object: log)
            logger.debug("\(log.message ?? "")")
        }
#endif
    }

    private func log(_ string: String) {
#if DEBUG
        logger.info("\(string)")
#endif
    }
}
