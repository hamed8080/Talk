//
//  TalkBackProxyViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/26/26.
//

import SwiftUI
import Foundation
import TalkExtensions
import Spec
import Combine
import Chat
import TalkModels

@MainActor
public class TalkBackProxyViewModel: ObservableObject {
    @Published public var isProxyMode: Bool = TalkBackProxyViewModel.hasProxy()
    @Published public var talkBackProxyAddress: String = proxy() ?? ""
    @Published public var isLoading = false
    @Published public var error: String?
    private var isValidAddress = true
    private static let KEY = "TALK-BACK-PROXY"
    public static let didChangeNotificationKey = "TALKBACK_PROXY_DID_CHANGE_KEY"
    private var cancellableSet: Set<AnyCancellable> = Set()

    public init() {
        register()
    }
    
    private func register() {
        $isProxyMode.sink { [weak self] newValue in
            self?.onModeChange(newIsProxyMode: newValue)
        }
        .store(in: &cancellableSet)
    }
    
    private func onModeChange(newIsProxyMode: Bool) {
        if !talkBackProxyAddress.isEmpty && newIsProxyMode {
            set(proxyAddress: talkBackProxyAddress)
        } else if !newIsProxyMode {
            clear()
        }
    }
    
    public func submit() async throws {
        talkBackProxyAddress = talkBackProxyAddress.lowercased()
        isValidAddress = isValid()
        
        error = nil
        if !isValidAddress {
            error = "Invalid Address"
            return
        }
        
        isLoading = true
        if !talkBackProxyAddress.isEmpty && isProxyMode {
            set(proxyAddress: talkBackProxyAddress)
            let spec = try await SpecManagerViewModel.shared.fetchConfigsReconnectIfSocketHasChanged()
            self.error = spec == nil ? "Wrong address" : nil
            isLoading = false
        }
    }
    
    private func isValid() -> Bool {
        return AddressValidator(value: talkBackProxyAddress).isValid()
    }
    
    public func set(proxyAddress: String) {
        UserDefaults.standard.set(proxyAddress, forKey: TalkBackProxyViewModel.KEY)
        NotificationCenter.default.post(name: TalkBackProxyViewModel.notifName(), object: nil)
    }
    
    public func clear() {
        UserDefaults.standard.removeObject(forKey: TalkBackProxyViewModel.KEY)
        NotificationCenter.default.post(name: TalkBackProxyViewModel.notifName(), object: nil)
        talkBackProxyAddress = TalkBackProxyViewModel.proxy() ?? ""
        let server = isSandBox() ? Server.defaultSandbox : Server.defaultMain
        let spec = Spec(servers: [server], server: server, paths: .defaultPaths, subDomains: .defaultSubdomains)
        AppState.shared.setSpec(spec)
        SpecManagerViewModel.shared.store(spec)
        Task {
            await SpecManagerViewModel.shared.fetchConfigsReconnectIfSocketHasChanged()
        }
    }
    
    private func isSandBox() -> Bool {
        SpecManagerViewModel.shared.isSandbox()
    }
    
    public static func hasProxy() -> Bool {
        UserDefaults.standard.string(forKey: KEY) != nil && UserDefaults.standard.string(forKey: KEY)?.isEmpty == false
    }
    
    public static func proxy() -> String? {
        UserDefaults.standard.string(forKey: KEY)
    }
    
    private static func notifName() -> NSNotification.Name {
        NSNotification.Name(TalkBackProxyViewModel.didChangeNotificationKey)
    }
}
