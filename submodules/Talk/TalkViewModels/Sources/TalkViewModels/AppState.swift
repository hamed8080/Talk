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
    public private(set) var user: User?
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
        user = UserConfigManagerVM.instance.currentUserConfig?.user
    }

    public func setUser(_ user: User?) {
        self.user = user
    }
    
    public func setUserBio(bio: String?) {
        user?.chatProfileVO?.bio = bio
    }
    
    public func updateWindowMode() {
        windowMode = UIApplication.shared.windowMode()
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task { @MainActor in
                AppState.isInSlimMode =
                UIApplication.shared.windowMode().isInSlimMode
                
                let newState = UIApplication.shared.windowMode()
                NotificationCenter.windowMode.post(name: .windowMode, object: newState)
            }
        }
        
        NotificationCenter.windowMode.post(
            name: .windowMode, object: windowMode)
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
    public func clear() {
        AppState.shared.objectsContainer.navVM.resetNavigationProperties()
        callLogs = nil
    }
}

// Lifesycle
extension AppState {
    public var isInForeground: Bool {
        lifeCycleState == .active || lifeCycleState == .foreground
    }
}
