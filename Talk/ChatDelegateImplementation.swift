//
//  ChatDelegateImplementation.swift
//  ChatImplementation
//
//  Created by Hamed Hosseini on 2/6/21.
//

import Chat
import ChatCore
import ChatDTO
import ChatModels
import Foundation
import Logger
import TalkExtensions
import TalkModels
import TalkViewModels
import UIKit
import OSLog

final class ChatDelegateImplementation: ChatDelegate {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Talk-App")
    private(set) static var sharedInstance = ChatDelegateImplementation()

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
                    AppState.shared.connectionStatus = .connected
                case .uninitialized:
                    self.log("Chat object is not initialized.")
                }
            }
        }
    }

    func chatEvent(event: ChatEventType) {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                NotificationCenter.post(event: event)
                switch event {
                case let .system(systemEventTypes):
                    self.onSystemEvent(systemEventTypes)
                case let .user(userEventTypes):
                    self.onUserEvent(userEventTypes)
                case let .message(response):
                    self.onMessageEvent(response)
                default:
                    break
                }
            }
        }
    }

    private func onUserEvent(_ event: UserEventTypes) {
        switch event {
        case let .user(response):
            if let user = response.result {
                UserConfigManagerVM.instance.onUser(user)
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

    private func onError(_ response: ChatResponse<Any>) {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                NotificationCenter.error.post(name: .error, object: response)
            }
        }
        guard let error = response.error else { return }
        if error.code == 21 {
            Task {
                let log = Log(prefix: "TALK_APP", time: .now, message: "Start a new Task in onError with error 21", level: .error, type: .sent, userInfo: nil)
                NotificationCenter.logs.post(name: .logs, object: log)
                await TokenManager.shared.getNewTokenWithRefreshToken()
            }
            AppState.shared.connectionStatus = .unauthorized
        } else {
            if response.isPresentable {
                AppState.shared.animateAndShowError(error)
            }
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        if case .new(let response) = event, let message = response.result, canNotify(response) {
            UNUserNotificationCenter.localNewMessageNotif(message, showName: AppSettingsModel.restore().notificationSettings.showDetails)
        }
    }

    private func canNotify(_ response: ChatResponse<Message>) -> Bool {
        response.result?.isMe(currentUserId: AppState.shared.user?.id) == false && AppState.shared.lifeCycleState == .background
    }

    func onLog(log: Log) {
        NotificationCenter.logs.post(name: .logs, object: log)
#if DEBUG
        logger.debug("\(log.message ?? "")")
#endif
    }

    private func log(_ string: String) {
#if DEBUG
        logger.info("\(string)")
#endif
    }
}
