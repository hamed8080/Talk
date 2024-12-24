//
//  ManageSessionsViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 6/27/22.
//

import TalkModels
import Foundation
import Chat

@MainActor
public final class ManageSessionsViewModel: ObservableObject {
    @Published public var sessions: [DeviceSession] = []
    private let size = 20
    private var offset = 0
    @Published public var isLoading = false
    
    public init() {}
    
    public func loadMore() async throws {
        offset = size + offset
        try await getDevices()
    }
    
    public func getDevices() async throws {
        isLoading = true
        let urlSession = URLSession(configuration: .default)
        let base = AppRoutes(serverType: .main).devices
        let url = URL(string: "\(base)?size=\(size)&offset=\(offset)")!
        var req = URLRequest(url: url)
        req.method = .get
        let token = await getToken()
        req.allHTTPHeaderFields = ["Authorization" : "Bearer \(token)"]
        let (data, _) = try await urlSession.data(for: req)
        let sessions = try JSONDecoder.instance.decode(SSODevicesList.self, from: data)
        await MainActor.run {
            self.sessions.append(contentsOf: sessions.devices)
            self.sessions.sort(by: {($0.current ?? false) == true && ($1.current ?? false) == false})
            isLoading = false
        }
    }
    
    public func removeAllSessions() async throws {
        let urlSession = URLSession(configuration: .default)
        let url = URL(string: AppRoutes(serverType: .main).devices)!
        var req = URLRequest(url: url)
        req.method = .delete
        let token = await getToken()
        req.allHTTPHeaderFields = ["Authorization" : "Bearer \(token)", "Content-Type" : "application/x-www-form-urlencoded"]
        let (data, response) = try await urlSession.data(for: req)
        if (response as? HTTPURLResponse)?.statusCode == 200 {
            await MainActor.run {
                self.sessions.removeAll()
            }
        }
    }
    
    public func removeSession(session: DeviceSession) async throws {
        let urlSession = URLSession(configuration: .default)
        guard let uid = session.uid else { throw URLError(.badURL) }
        let url = URL(string: "\(AppRoutes(serverType: .main).devices)/\(uid)")!
        var req = URLRequest(url: url)
        req.method = .delete
        let token = await getToken()
        req.allHTTPHeaderFields = ["Authorization" : "Bearer \(token)", "Content-Type" : "application/x-www-form-urlencoded"]
        let (data, response) = try await urlSession.data(for: req)
        if (response as? HTTPURLResponse)?.statusCode == 200 {
            await MainActor.run {
                self.sessions.removeAll(where: {$0.id == session.id})
            }
        }
    }
    
    @ChatGlobalActor
    private func getToken() async -> String {
        return await ChatManager.activeInstance?.config.token ?? ""
    }
}
