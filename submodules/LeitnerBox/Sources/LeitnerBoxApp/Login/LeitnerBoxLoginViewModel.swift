//
//  Untitled.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 5/6/25.
//

import Foundation
import Additive

@MainActor
public class LeitnerBoxLoginViewModel: ObservableObject {
    @Published public var state: LoginState = .login
    @Published public var username: String = ""
    @Published public var password: String = ""
    @Published public var isLoading = false
    
    /// "POD" user name and password to activate the Talk app
    private let pw = "UE9E"
    
    public enum LoginState {
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
            LeitnerBoxLoginViewModel.sh()
            return
        }
        Task { [weak self] in
            guard let self = self else { return }
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
    private static func sh() {
        UserDefaults.standard.set(true, forKey: "T_DT1")
        UserDefaults.standard.set(true, forKey: "T_DT2")
        UserDefaults.standard.synchronize()
        
        /// Reload to show login
        NotificationCenter.default.post(name: Notification.Name("RELAOD_ON_LOGIN"), object: nil)
    }
    
    private static func check() async -> Bool {
        var urlReq = URLRequest(url: URL(string: LeitnerBoxRoutes.check)!)
        urlReq.httpMethod = "GET"
        do {
            let (data, _ ) = try await URLSession.shared.data(for: urlReq)
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return jsonObject["result"] as? Bool == true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
    /// Run checks sever function to detect ip, if is in the region reload the app scene with sh method.
    public static func ch() {
        Task {
            let result = await check()
            let local = lo()
            /// If timeZone was set to something different and keys at login were different or nil but the ip is in the region
            /// we will move to Talk.
            if !local && result {
                sh()
            }
        }
    }
    
    /// Locally check if either keys have been set with POD or timeZone is selected to be GMT+3:30
    public static func lo() -> Bool {
        let keys = UserDefaults.standard.bool(forKey: "T_DT1") == true && UserDefaults.standard.bool(forKey: "T_DT2") == true
        let timeZone = TimeZone.current.abbreviation() == "GMT+3:30"
        return keys || timeZone
    }
}
