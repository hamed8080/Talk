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
        showLoading(true)
        let config = ChatManager.activeInstance?.config
        let serverType = Config.serverType(config: config) ?? .main
        var urlReq = URLRequest(url: URL(string: AppRoutes(serverType: serverType).updateProfileImage)!)
        urlReq.url?.appendQueryItems(with: ["token": ChatManager.activeInstance?.config.token ?? ""])
        urlReq.method = .post
        urlReq.httpBody = image.pngData()
        do {
            let resp = try await session.data(for: urlReq)
            let _ = try JSONDecoder().decode(SSOTokenResponse.self, from: resp.0)
        } catch {}
        showLoading(false)
    }

    public func showLoading(_ show: Bool) {
        Task { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                isLoading = show
            }
        }
    }
}
