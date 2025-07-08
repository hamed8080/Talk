//
//  LeitnerBoxDeleteAccountViewModel.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 5/29/25.
//

import Foundation

@MainActor
class LeitnerBoxDeleteAccountViewModel: ObservableObject {
    @Published public var state: RegisterState = .register
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var isLoading = false
    
    enum RegisterState {
        case register
        case failed
        case success
    }
    
    struct DeleteAccountRequest: Codable {
        let email: String
        let password: String
    }
    
    public func deleteAccount() {
        isLoading = true
        var urlReq = URLRequest(url: URL(string: LeitnerBoxRoutes.deleteAccount)!)
        let req = DeleteAccountRequest(email: email, password: password)
        let data = try? JSONEncoder().encode(req)
        urlReq.httpBody = data
        urlReq.httpMethod = "POST"
        urlReq.allHTTPHeaderFields = ["Content-Type": "application/json"]
        Task {
            do {
                let resp = try await URLSession.shared.data(for: urlReq)
                if let httpResp = resp.1 as? HTTPURLResponse, httpResp.statusCode == 200 {
                    state = .success
                    UserDefaults.standard.removeObject(forKey: "leitner_token")
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
