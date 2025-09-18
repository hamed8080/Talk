//
//  AppState.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/4/21.
//

import Chat
import Combine
import SwiftUI
import TalkExtensions
import TalkModels

@MainActor
public final class AppState: ObservableObject, Sendable {
    public static let shared = AppState()
    public var spec: Spec = Spec.empty
    public var user: User?
    @Published public var error: ChatError?
    @Published public var isLoading: Bool = false
    @Published public var callLogs: [URL]?
    private var cancelable: Set<AnyCancellable> = []
    public var windowMode: WindowMode = .iPhone
    public static var isInSlimMode = AppState.shared.windowMode.isInSlimMode
    public var lifeCycleState: AppLifeCycleState?
    public var objectsContainer: ObjectsContainer!
    @Published public var connectionStatus: ConnectionStatus = .connecting
    
    private init() {
        registerObservers()
        updateWindowMode()
        updateUserCache(user: UserConfigManagerVM.instance.currentUserConfig?.user)
    }

    public func updateUserCache(user: User?) {
        self.user = user
    }
    
    public func updateWindowMode() {
        windowMode = UIApplication.shared.windowMode()
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task { @MainActor in
                AppState.isInSlimMode =
                UIApplication.shared.windowMode().isInSlimMode
            }
        }
        
        NotificationCenter.windowMode.post(
            name: .windowMode, object: windowMode)
    }
    
    public func animateAndShowError(_ error: ChatError) {
        withAnimation {
            isLoading = false
            self.error = error
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) {
                [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.error = nil
                }
            }
        }
    }
}

// Observers.
extension AppState {
    private func registerObservers() {
        UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }).publisher.sink { [weak self] newValue in
            self?.updateWindowMode()
        }
        .store(in: &cancelable)
    }
}

extension AppState {
    public func openURL(url: URL) {
        NotificationCenter.default.post(name: NSNotification.Name("openURL"), object: url)
        animateObjectWillChange()
    }
}

extension AppState {
    public func clear() {
        AppState.shared.objectsContainer.navVM.resetNavigationProperties()
        callLogs = nil
        error = nil
        isLoading = false
    }
}

// Lifesycle
extension AppState {
    public var isInForeground: Bool {
        lifeCycleState == .active || lifeCycleState == .foreground
    }
}

extension AppState {    
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
