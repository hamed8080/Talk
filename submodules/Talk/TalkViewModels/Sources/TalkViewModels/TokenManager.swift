//
//  TokenManager.swift
//  TalkViewModels
//
//  Created by hamed on 3/16/23.
//

import Chat
import Foundation
import TalkModels
import OSLog
import Logger
import TalkExtensions

public final class TokenManager: ObservableObject {
    public static let shared = TokenManager()
    @Published public var secondToExpire: Double = 0
    @Published public private(set) var isLoggedIn = false // to update login logout ui
    public static let ssoTokenKey = "ssoTokenKey"
    public static let ssoTokenCreateDate = "ssoTokenCreateDate"
    public let session: URLSession
    public var isInFetchingRefreshToken = false

    private init(session: URLSession = .shared) {
        self.session = session
        getSSOTokenFromUserDefaults() // need first time app luanch to set hasToken
    }

    public func getPKCENewTokenWithRefreshToken() async {
        guard let ssoTokenModel = getSSOTokenFromUserDefaults(),
              let codeVerifier = ssoTokenModel.codeVerifier
        else { return }
        do {
            let refreshToken = ssoTokenModel.refreshToken ?? ""
            let urlReq = pkceURLRequest(refreshToken: refreshToken, codeVerifier: codeVerifier)
            let resp = try await session.data(for: urlReq)
            let log = Logger.makeLog(prefix: "TALK_APP_REFRESH_TOKEN:", request: urlReq, response: resp)
            post(log: log)
            var ssoToken = try JSONDecoder().decode(SSOTokenResponse.self, from: resp.0)
            ssoToken.codeVerifier = codeVerifier
            await onNewRefreshToken(ssoToken)
        } catch {
            onRefreshTokenError(error: error)
        }
    }

    private func pkceURLRequest(refreshToken: String, codeVerifier: String) -> URLRequest {
        let clientId = "88413l69cd4051a039cf115ee4e073"
        let url = URL(string: AppRoutes(serverType: .main).ssoToken)!
        var urlReq = URLRequest(url: url)
        urlReq.url?.append(queryItems: [.init(name: "refreshToken", value: refreshToken)])
        urlReq.httpMethod = "POST"
        urlReq.httpBody = NSMutableData(data: "grant_type=refresh_token&client_id=\(clientId)&code_verifier=\(codeVerifier)&refresh_token=\(refreshToken)".data(using: String.Encoding.utf8)!) as Data
        urlReq.allHTTPHeaderFields = ["content-type": "application/x-www-form-urlencoded"]
        return urlReq
    }

    private func otpURLrequest(refreshToken: String, keyId: String) -> URLRequest {
        let config = ChatManager.activeInstance?.config
        let serverType = Config.serverType(config: config) ?? .main
        var urlReq = URLRequest(url: URL(string: AppRoutes(serverType: serverType).refreshToken)!)
        urlReq.url?.append(queryItems: [.init(name: "refreshToken", value: refreshToken)])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
        return urlReq
    }
    
    @MainActor
    public func getNewTokenWithRefreshToken() async throws {
        if isInFetchingRefreshToken { return }
        isInFetchingRefreshToken = true
        try await getOTPNewTokenWithRefreshToken()
        isInFetchingRefreshToken = false
    }

    public func getOTPNewTokenWithRefreshToken() async throws {
        guard let ssoTokenModel = getSSOTokenFromUserDefaults(),
              let keyId = ssoTokenModel.keyId
        else { return }
        do {
            let refreshToken = ssoTokenModel.refreshToken ?? ""
            let urlReq = otpURLrequest(refreshToken: refreshToken, keyId: keyId)
            let tuple = try await session.data(for: urlReq)
            if let resp = tuple.1 as? HTTPURLResponse, resp.statusCode >= 400 && resp.statusCode < 500 {
                throw AppErrors.revokedToken
                return
            }
            let log = Logger.makeLog(prefix: "TALK_APP_REFRESH_TOKEN:", request: urlReq, response: tuple)
            post(log: log)
            var ssoToken = try JSONDecoder().decode(SSOTokenResponse.self, from: tuple.0)
            ssoToken.keyId = keyId
            await onNewRefreshToken(ssoToken)
        } catch {
            onRefreshTokenError(error: error)
            throw error
        }
    }
    
    private func onNewRefreshToken(_ ssoToken: SSOTokenResponse) async {
        await MainActor.run {
            saveSSOToken(ssoToken: ssoToken)
            ChatManager.activeInstance?.setToken(newToken: ssoToken.accessToken ?? "", reCreateObject: false)
            if AppState.shared.connectionStatus != .connected {
                AppState.shared.connectionStatus = .connected
                let log = Log(prefix: "TALK_APP", time: .now, message: "App State was not connected and set token just happend without set observeable", level: .error, type: .sent, userInfo: nil)
                post(log: log)
            } else {
                let log = Log(prefix: "TALK_APP", time: .now, message: "App State was connected and set token just happend without set observeable", level: .error, type: .sent, userInfo: nil)
                post(log: log)
            }
        }
    }

    private func onRefreshTokenError(error: Error) {
        let log = Log(prefix: "TALK_APP", time: .now, message: error.localizedDescription, level: .error, type: .sent, userInfo: nil)
        post(log: log)
        self.log("error on getNewTokenWithRefreshToken:\(error.localizedDescription)")
    }

    @discardableResult
    public func getSSOTokenFromUserDefaults() -> SSOTokenResponse? {
        if let data = UserDefaults.standard.data(forKey: TokenManager.ssoTokenKey), let ssoToken = try? JSONDecoder().decode(SSOTokenResponse.self, from: data) {
            return ssoToken
        } else {
            return nil
        }
    }

    /// For checking the user is login at application launch
    public func initSetIsLogin() {
        isLoggedIn = getSSOTokenFromUserDefaults() != nil
    }

    public func saveSSOToken(ssoToken: SSOTokenResponse) {
        let data = (try? JSONEncoder().encode(ssoToken)) ?? Data()
        let str = String(data: data, encoding: .utf8)
        log("save token:\n\(str ?? "")")
        UserConfigManagerVM.instance.updateToken(ssoToken)
        refreshCreateTokenDate()
        if let encodedData = try? JSONEncoder().encode(ssoToken) {
            Task {
                await MainActor.run {
                    UserDefaults.standard.set(encodedData, forKey: TokenManager.ssoTokenKey)
                    UserDefaults.standard.synchronize()
                }
            }
        }
        setIsLoggedIn(isLoggedIn: true)
    }

    public func refreshCreateTokenDate() {
        Task.detached(priority: .background) {
            await MainActor.run {
                UserDefaults.standard.set(Date(), forKey: TokenManager.ssoTokenCreateDate)
            }
        }
    }

    public func getCreateTokenDate() -> Date? {
        UserDefaults.standard.value(forKey: TokenManager.ssoTokenCreateDate) as? Date
    }

    public func setIsLoggedIn(isLoggedIn: Bool) {
        Task { [weak self] in
            guard let self = self else { return }
            await MainActor.run {
                self.isLoggedIn = isLoggedIn
            }
        }
    }

    public func clearToken() {
        UserDefaults.standard.removeObject(forKey: TokenManager.ssoTokenKey)
        UserDefaults.standard.removeObject(forKey: TokenManager.ssoTokenCreateDate)
        UserDefaults.standard.synchronize()
        setIsLoggedIn(isLoggedIn: false)
    }

    public func startTokenTimer() {
#if DEBUG
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            if let createDate = TokenManager.shared.getCreateTokenDate(), let ssoTokenExipreTime = TokenManager.shared.getSSOTokenFromUserDefaults()?.expiresIn {
                let expireIn = createDate.advanced(by: Double(ssoTokenExipreTime)).timeIntervalSince1970 - Date().timeIntervalSince1970
                self?.secondToExpire = Double(expireIn)
            }
        }
#endif
    }

    private func post(log: Log) {
#if DEBUG
        NotificationCenter.logs.post(name: .logs, object: log)
#endif
    }

    private func log(_ message: String) {
#if DEBUG
        Logger.viewModels.info("\(message)")
#endif
    }
}
