//
//  SettingViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Chat
import Combine
import SwiftUI
import TalkModels

@MainActor
public final class SettingViewModel: ObservableObject {
    public private(set) var cancellableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    public var isLoading: Bool = false
    @Published public var showImagePicker: Bool = false
    public let session: URLSession
    @Published public var isEditing: Bool = false

    public init(session: URLSession = .shared) {
        self.session = session
        AppState.shared.$connectionStatus
            .sink{ [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancellableSet)
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            firstSuccessResponse = true
        }
    }

    public func updateProfilePicture(image: UIImage?) async {
        guard let image = image else { return }        
        await showLoading(true)
        let config = await config()
        let serverType = Config.serverType(config: config) ?? .main
        var urlReq = URLRequest(url: URL(string: AppRoutes(serverType: serverType).updateProfileImage)!)
        urlReq.url?.appendQueryItems(with: ["token": config?.token ?? ""])
        urlReq.method = .post
        urlReq.httpBody = image.pngData()
        do {
            let resp = try await session.data(for: urlReq)
            let _ = try JSONDecoder().decode(SSOTokenResponse.self, from: resp.0)
        } catch {}
        await showLoading(false)
    }
    
    @ChatGlobalActor
    private func config() -> ChatConfig? {
        ChatManager.activeInstance?.config
    }

    @MainActor
    public func showLoading(_ show: Bool) async {
        isLoading = show
    }
}
