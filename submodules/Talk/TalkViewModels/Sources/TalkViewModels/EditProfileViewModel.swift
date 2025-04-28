//
//  EditProfileViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat
import UIKit
import Photos
import Combine

@MainActor
public final class EditProfileViewModel: ObservableObject {
    @Published public var isLoading: Bool = false
    @Published public var firstName: String = ""
    @Published public var lastName: String = ""
    @Published public var userName: String = ""
    @Published public var bio: String = ""
    @Published public var showImagePicker: Bool = false
    @Published public var dismiss: Bool = false
    public var image: UIImage?
    public var assetResources: [PHAssetResource] = []
    public var temporaryDisable: Bool = true
    private var cancelable: Set<AnyCancellable> = []
    private var objectId = UUID().uuidString
    private let UPDATE_USER_INFO_KEY: String

    public init() {
        UPDATE_USER_INFO_KEY = "UPDATE-USER-INFO-\(objectId)"
        let user = AppState.shared.user
        firstName = user?.name ?? ""
        lastName = user?.lastName ?? ""
        userName = user?.username ?? ""
        bio = user?.chatProfileVO?.bio ?? ""

        NotificationCenter.user.publisher(for: .user)
            .compactMap { $0.object as? UserEventTypes }
            .sink { [weak self] event in
                if case .setProfile(let response) = event {
                    self?.onUpdateProfile(response)
                }
            }
            .store(in: &cancelable)
    }

    public func submit() {
        let req = UpdateChatProfile(bio: bio)
        RequestsManager.shared.append(prepend: UPDATE_USER_INFO_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.user.set(req)
        }
    }

    private func onUpdateProfile(_ response: ChatResponse<Profile>) {
        self.bio = response.result?.bio ?? ""
        if response.error == nil, response.pop(prepend: UPDATE_USER_INFO_KEY) != nil {
            dismiss = true
        }
    }
}
