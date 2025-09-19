//
//  ChatDelegateImplementation.swift
//  ChatImplementation
//
//  Created by Hamed Hosseini on 2/6/21.
//

import Chat
import Foundation
import Logger
import SwiftUI

@_exported import TalkModels
@_exported import TalkViewModels
@_exported import TalkExtensions
@_exported import TalkUI
@_exported import Logger

@MainActor
public final class ChatDelegateImplementation: ChatDelegate {
    private var retryCount = 0
    public private(set) static var sharedInstance = ChatDelegateImplementation()
    
    public func initialize() {
        let manager = BundleManager.init()
        if let spec = Spec.cachedSpec(), manager.hasBundle {
            if let language = Language.languages.first(where: {$0.language == Locale.preferredLanguages[0] }) {
                Language.setLanguageTo(bundle: manager.getBundle(), language: language)
            }
            setup(spec: spec, bundle: manager.getBundle())
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    let updated = try await manager.shouldUpdate()
                    if updated {
                        reload(spec: spec, bundle: manager.getBundle(), recreateChatObject: false)
                    }
                } catch {
                    print(error)
                }
            }
        } else {
            /// Download Spec and Bundle
            Task { [weak self] in
                guard let self = self else { return }
                await dlReload(manager: manager)
            }
        }
    }
    
    private func dlReload(manager: BundleManager) async {
        do {
            let spec = try await Spec.dl()
            _ = try await manager.st()
            reload(spec: spec, bundle: manager.getBundle())
        } catch {
            // Failed to download spec or bundle
            if retryCount < 3 {
                retryCount += 1
                await dlReload(manager: manager)
            }
        }
    }
    
    private func reload(spec: Spec, bundle: Bundle, recreateChatObject: Bool = true) {
        if let language = Language.languages.first(where: { $0.identifier == "ZmFfSVI=".fromBase64() }) {
            Language.setLanguageTo(bundle: bundle, language: language)
        }
        setup(spec: spec ?? .empty, bundle: bundle, recreateChatObject: recreateChatObject)
        NotificationCenter.default.post(name: Notification.Name("RELAOD"), object: nil)
    }
    
    private func setup(spec: Spec, bundle: Bundle, recreateChatObject: Bool = true) {
        AppState.shared.spec = spec
        UIFont.register(bundle: bundle)
        // Override point for customization after application launch.
        if recreateChatObject {
            createChatObject()
        }
    }

    func createChatObject() {
        if let userConfig = UserConfigManagerVM.instance.currentUserConfig, let userId = userConfig.id {
            UserConfigManagerVM.instance.createChatObjectAndConnect(userId: userId, config: userConfig.config, delegate: self)
            TokenManager.shared.initSetIsLogin()
        }
    }

    nonisolated public func chatState(state: ChatState, currentUser: User?, error _: ChatError?) {
        Task { [weak self] in
            guard let self = self else { return }
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
                    AppState.shared.objectsContainer.chatRequestQueue.cancellAll()
                    AppState.shared.connectionStatus = .connected                    
                case .uninitialized:
                    self.log("Chat object is not initialized.")
                }
            }
        }
    }

    nonisolated public func chatEvent(event: ChatEventType) {
        let copy = event
        Task { @MainActor [weak self] in
            guard let self = self else { return }
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

    private func onUserEvent(_ event: UserEventTypes) {
        switch event {
        case let .user(response):
            if let user = response.result {
                UserConfigManagerVM.instance.onUser(user)
                AppState.shared.setUser(user)
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
            clearQueueRequestsOnUnAuthorizedError()
            tryRefreshToken()
        } else {
            if response.isPresentable {
                Task { @MainActor in
                    AppState.shared.objectsContainer.appOverlayVM.showErrorToast(error)
                }
            }
        }
    }

    private func tryRefreshToken() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
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
    
    public func logout() async {
        AppState.shared.setUser(nil)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.user.logOut()
        }
        TokenManager.shared.clearToken()
        UserConfigManagerVM.instance.logout(delegate:  self)
        await AppState.shared.objectsContainer.reset()
    }
    
    private func clearQueueRequestsOnUnAuthorizedError() {
        RequestsManager.shared.clear()
        AppState.shared.objectsContainer.chatRequestQueue.cancellAll()
    }
    
    private static var isLogOnDisk: Bool = {
        (Bundle.main.object(forInfoDictionaryKey: "LOG_ON_DISK") as? NSNumber)?.boolValue == true
    }()

    nonisolated public func onLog(log: Log) {
        /// Some logs will not stores inside the SDKs
        /// so to see them inside the LogViewModel we have to use this to save them on CDLog table
        /// and then refetch them in 5 seconds period.
        Task { @MainActor in
            Logger.log(title: log.prefix ?? "", message: log.message ?? "", persist: ChatDelegateImplementation.isLogOnDisk)
        }
    }

    private func log(_ string: String) {
        Logger.log(title: "ChatDelegateImplementation.onLog", message: string)
    }
}
