//
//  LeitnerBoxForgetViewModel.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 5/6/25.
//

import Foundation

@MainActor
class LeitnerBoxForgetViewModel: ObservableObject {
    @Published public var state: ForgetState = .forget
    @Published public var email: String = ""
    @Published public var isLoading = false
    
    enum ForgetState {
        case forget
        case failed
        case success
    }
    
    struct ForgetRequest: Codable {
        let email: String
    }
    
    public func requestForgetPassword() {
        isLoading = true
        var urlReq = URLRequest(url: URL(string: LeitnerBoxRoutes.forgot)!)
        let req = ForgetRequest(email: email)
        let data = try? JSONEncoder().encode(req)
        urlReq.httpBody = data
        urlReq.httpMethod = "POST"
        urlReq.allHTTPHeaderFields = ["Content-Type": "application/json"]
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let resp = try await URLSession.shared.data(for: urlReq)
                if let httpResp = resp.1 as? HTTPURLResponse, httpResp.statusCode == 200 {
                    state = .success
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
