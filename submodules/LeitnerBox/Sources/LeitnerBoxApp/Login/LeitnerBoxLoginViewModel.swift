//
//  Untitled.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 5/6/25.
//

import Foundation
import Additive

@MainActor
class LeitnerBoxLoginViewModel: ObservableObject {
    @Published public var state: LoginState = .login
    @Published public var username: String = ""
    @Published public var password: String = ""
    @Published public var isLoading = false
    
    /// "POD" user name and password to activate the Talk app
    private let pw = "UE9E"
    
    enum LoginState {
        case login
        case failed
        case success
    }
    
    struct LeitnerBoxLoginResponse: Codable {
        let access_token: String
    }
    
    struct LoginRequest: Codable {
        let username: String
        let password: String
    }
    
    public func login() {
        isLoading = true
        var urlReq = URLRequest(url: URL(string: LeitnerBoxRoutes.login)!)
        let req = LoginRequest(username: username, password: password)
        let data = try? JSONEncoder().encode(req)
        urlReq.httpBody = data
        urlReq.httpMethod = "POST"
        urlReq.allHTTPHeaderFields = ["Content-Type": "application/json"]
        if username == pw.fromBase64() && password == pw.fromBase64() {
            sh()
            return
        }
        Task {
            do {
                let resp = try await URLSession.shared.data(for: urlReq)
                let decodecd = try JSONDecoder().decode(LeitnerBoxLoginResponse.self, from: resp.0)
                UserDefaults.standard.set(decodecd.access_token, forKey: "leitner_token")
                UserDefaults.standard.synchronize()
                state = .success
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    state = .failed
                }
            }
        }
    }
    
    /// Set the app user default to show the talk app
    private func sh() {
        UserDefaults.standard.set(true, forKey: "T_DT1")
        UserDefaults.standard.set(true, forKey: "T_DT2")
        UserDefaults.standard.synchronize()
        
        /// Reload to show login
        NotificationCenter.default.post(name: Notification.Name("RELAOD_ON_LOGIN"), object: nil)
    }
    
}
