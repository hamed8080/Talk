//
//  LeitnerBoxRegisterViewModel.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 5/6/25.
//

import Foundation

@MainActor
class LeitnerBoxRegisterViewModel: ObservableObject {
    @Published public var state: RegisterState = .register
    @Published public var username: String = ""
    @Published public var password: String = ""
    @Published public var email: String = ""
    @Published public var isLoading = false
    
    enum RegisterState {
        case register
        case failed
        case success
    }
    
    struct RegisterRequest: Codable {
        let username: String
        let password: String
        let email: String
    }
    
    struct LeitnerBoxRegisterResponse: Codable {
        let access_token: String
    }
    
    public func register() {
        isLoading = true
        var urlReq = URLRequest(url: URL(string: LeitnerBoxRoutes.register)!)
        let req = RegisterRequest(username: username, password: password, email: email)
        let data = try? JSONEncoder().encode(req)
        urlReq.httpBody = data
        urlReq.httpMethod = "POST"
        urlReq.allHTTPHeaderFields = ["Content-Type": "application/json"]
        Task {
            do {
                let resp = try await URLSession.shared.data(for: urlReq)
                if let httpResp = resp.1 as? HTTPURLResponse, httpResp.statusCode == 200 {
                    state = .success
                    let decodecd = try JSONDecoder().decode(LeitnerBoxRegisterResponse.self, from: resp.0)
                    UserDefaults.standard.set(decodecd.access_token, forKey: "leitner_token")
                    UserDefaults.standard.synchronize()
                } else {
                    state = .failed
                }
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
}
