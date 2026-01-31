//
//  SpecManagerViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/26/26.
//

import Foundation
import TalkExtensions
import TalkModels
import Spec
import Chat

@MainActor
public class SpecManagerViewModel {
    private let key = "SPEC_KEY"
    public static let shared = SpecManagerViewModel()
    private var firstAttempt = false
    public weak var delegate: ChatDelegate?
    private var timer: Timer? = nil
    private let timerInterval = TimeInterval(30 * 60) // 30 minutes
    
    private init() {}
    
    public enum TalkBackSpecError: Error {
        case failed
    }
    
    public func download() async throws -> Spec {
        let hasProxy = TalkBackProxyViewModel.hasProxy()
        let hasEverCached = hasEverCached()
        if !hasEverCached {
            return try await downloadInitPodsapceSpec()
        } else if hasProxy {
            return try await downloadProxySpec()
        } else {
            do {
                return try await downloadDefaultTalkBackSpec()
            } catch {
                return try await downloadDefaultSecondTalkBackSpec()
            }
        }
    }
    
    private func downloadDefaultTalkBackSpec() async throws -> Spec {
        firstAttempt = true
        let baseAddress = isSandbox() ? Constants.talkBackSandbox.fromBase64() ?? "" : Constants.talkBackProductionSpecURL.fromBase64() ?? ""
        let address = baseAddress
        let token = token()
        let spec = try await requestParseStore(string: address, token: token)
        scheduleRefetchTimer()
        return spec
    }
    
    private func downloadDefaultSecondTalkBackSpec() async throws -> Spec {
        let address = isSandbox() ? Constants.talkBackSecondSandboxSpecURL.fromBase64() ?? "" : Constants.talkBackSecondSpecURL.fromBase64() ?? ""
        let token = token()
        let spec = try await requestParseStore(string: address, token: token)
        scheduleRefetchTimer()
        return spec
    }
    
    private func downloadInitPodsapceSpec() async throws -> Spec {
        let address = Constants.podspacePublicSpec.fromBase64() ?? ""
        let spec = try await requestParseStore(string: address, token: nil)
        return spec
    }
    
    private func downloadProxySpec() async throws -> Spec {
        let baseAddress = TalkBackProxyViewModel.proxy() ?? ""
        let path = Constants.talkBackConfigsPath.fromBase64() ?? ""
        let address = "\(baseAddress)\(path)"
        let token = token()
        let spec = try await requestParseStore(string: address, token: token)
        return spec
    }
    
    private func requestParseStore(string: String, token: String?) async throws -> Spec {
        let (data, _) = try await request(string: string, token: token)
        let spec = try await parseResponse(data: data, parsePodspace: token == nil)
        store(spec)
        return spec
    }
    
    private func request(string: String, token: String?) async throws -> (data: Data, response: URLResponse) {
        guard let url = URL(string: string)
        else { throw URLError.init(.badURL) }
        
        var req = URLRequest(url: url, timeoutInterval: 10.0)
        req.method = .get
        if let token = token {
            req.allHTTPHeaderFields = ["Authorization": "Bearer \(token)"]
        }
        
        let (data, response) = await try URLSession.shared.data(req)
        
        if let response = response as? HTTPURLResponse, response.statusCode != 200 {
            throw TalkBackSpecError.failed
        }
        
        return (data, response)
    }
    
    private func parseResponse(data: Data, parsePodspace: Bool) throws -> Spec {
        if parsePodspace {
            return try parsePodspaceResponse(data: data)
        }
        return try parseTalkSpecResponse(data: data)
    }
    
    private func parseTalkSpecResponse(data: Data) throws -> Spec {
        return try JSONDecoder.instance.decode(TalkBackSpec.self, from: data).toSpec(isSandbox: isSandbox())
    }
    
    private func parsePodspaceResponse(data: Data) throws -> Spec {
        return try JSONDecoder.instance.decode(Spec.self, from: data)
    }
    
    public func store(_ spec: Spec) {
        UserDefaults.standard.setValue(codable: spec, forKey: key)
    }
    
    public func cachedSpec() -> Spec? {
        return UserDefaults.standard.codableValue(forKey: key)
    }
    
    public func token() -> String? {
        TokenManager.shared.getToken()
    }
    
    public func isSandbox() -> Bool {
        return cachedSpec()?.server.server == ServerTypes.sandbox.rawValue
    }
    
    public func getConfigsOnToken() async throws -> Spec {
        do {
            let spec = await try downloadDefaultTalkBackSpec()
            return spec
        } catch {
            let spec = await try downloadDefaultSecondTalkBackSpec()
            return spec
        }
    }
}

extension SpecManagerViewModel {
    private func isCurrentSokectChanged() async -> Bool {
        let chatConfig = await getChatConfig()
        return cachedSpec()?.server.socket != chatConfig?.spec.server.socket
    }
    
    @ChatGlobalActor
    private func getChatConfig() -> ChatConfig? {
        ChatManager.activeInstance?.config
    }
    
    public func fetchConfigsReconnectIfSocketHasChanged() async -> Spec? {
        /// We will not sending request if we have never fetched podspace public spec.
        if !hasEverCached() { return nil }
        
        let token = TokenManager.shared.getToken()
    
        guard let spec = try? await refetchAndStoreConfigs(),
              let token = token
        else { return nil }
        if await !isCurrentSokectChanged() { return spec }
        
        reconnect(token: token, spec: spec)
        return spec
    }
    
    private func refetchAndStoreConfigs() async throws -> Spec {
        if TalkBackProxyViewModel.hasProxy() {
            return try await downloadProxySpec()
        }
        do {
            return await try downloadDefaultTalkBackSpec()
        } catch {
            return await try downloadDefaultSecondTalkBackSpec()
        }
    }
    
    private func reconnect(token: String, spec: Spec) {
        let config = Spec.config(spec: spec, token: token)
        UserConfigManagerVM.instance.createChatObjectAndConnect(userId: nil, config: config, delegate: delegate)
    }
    
    private func scheduleRefetchTimer() {
        timer?.invalidate()
        timer = nil
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: false, block: { [weak self] _ in
            Task { [weak self] in
                await self?.fetchConfigsReconnectIfSocketHasChanged()
            }
        })
    }
    
    private func hasEverCached() -> Bool {
        cachedSpec()?.server.socket.isEmpty == false
    }
}
