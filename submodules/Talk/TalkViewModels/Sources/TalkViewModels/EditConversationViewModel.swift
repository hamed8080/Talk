//
//  EditConversationViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import UIKit
import Combine
import Photos
import TalkModels
import Chat

public final class EditConversationViewModel: ObservableObject, Hashable {
    public static func == (lhs: EditConversationViewModel, rhs: EditConversationViewModel) -> Bool {
        lhs.thread.id == rhs.thread.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread.id)
    }

    public weak var threadVM: ThreadViewModel?
    private(set) var cancelable: Set<AnyCancellable> = []
    public var uploadProfileUniqueId: String?
    public var uploadProfileProgress: Int64?
    public var image: UIImage?
    public var assetResources: [PHAssetResource] = []
    @Published public var isLoading = false
    @Published public var isPublic = false
    @Published public var editTitle: String = ""
    @Published public var threadDescription: String = ""
    public var dismiss: Bool = false
    public var thread: Conversation { threadVM?.thread ?? .init() }
    @Published public var adminCounts: Int = 0
    @Published public var isReactionsEnabled: Bool = true
    private var objectId = UUID().uuidString
    private let EDIT_GROUP_KEY: String
    private let CHANGE_TO_PUBLIC_KEY: String
    private let EDIT_GROUP_ADMINS_KEY: String
    private var enableReactionEvent = false

    public init(threadVM: ThreadViewModel?) {
        EDIT_GROUP_KEY = "EDIT-GROUP-\(objectId)"
        CHANGE_TO_PUBLIC_KEY = "CHANGE-TO-PUBLIC-\(objectId)"
        EDIT_GROUP_ADMINS_KEY = "EDIT-GROUP-ADMINS-\(objectId)"
        self.threadVM = threadVM
        editTitle = thread.title?.replacingOccurrences(of: NSRegularExpression.emojiRegEx, with: "\\\\u{$1}", options: .regularExpression) ?? ""
        threadDescription = thread.description ?? ""
        isPublic = thread.type?.isPrivate == false
        registerObservers()
        isReactionsEnabled = threadVM?.thread.reactionStatus == .enable || threadVM?.thread.reactionStatus == .custom
        delayEnableReactionEventForASecond()
    }

    private func registerObservers() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
            .store(in: &cancelable)
        NotificationCenter.participant.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { [weak self] value in
                self?.onParticipantsEvent(value)
            }
            .store(in: &cancelable)
        NotificationCenter.upload.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink { [weak self] value in
                self?.onUploadEvent(value)
            }
            .store(in: &cancelable)

        NotificationCenter.reaction.publisher(for: .reaction)
            .compactMap { $0.object as? ReactionEventTypes }
            .sink { [weak self] value in
                self?.onReactionEvent(value)
            }
            .store(in: &cancelable)

        $isReactionsEnabled
            .sink { [weak self] newValue in
                if self?.enableReactionEvent == true {
                    self?.onReactionSwitchChanged(newValue)
                }
            }
            .store(in: &cancelable)
    }

    private func onReactionSwitchChanged(_ isEnabled: Bool) {
        isLoading = true
        let req = ConversationCustomizeReactionsRequest(conversationId: thread.id ?? -1, reactionStatus: isEnabled ? .enable : .disable)
        ChatManager.activeInstance?.reaction.customizeReactions(req)
    }

    private func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .progress(let uniqueId, let progress):
            onUploadConversationProfile(uniqueId, progress)
        default:
            break
        }
    }

    private func onUploadConversationProfile(_ uniqueId: String, _ progress: UploadFileProgress?) {
        if uniqueId == uploadProfileUniqueId {
            uploadProfileProgress = progress?.percent ?? 0
            animateObjectWillChange()
        }
    }

    /// If the image information '' is nil we have to send a name for our file unless we will end up with an error from podspace,
    /// so we have to fill it with UUID().uuidString.
    public func submitEditGroup() {
        isLoading = true
        guard let threadId = thread.id else { return }
        var imageRequest: UploadImageRequest?
        if let image = image {
            let width = Int(image.size.width)
            let height = Int(image.size.height)
            imageRequest = UploadImageRequest(data: image.pngData() ?? Data(),
                                              fileExtension: "png",
                                              fileName: assetResources.first?.originalFilename ?? UUID().uuidString,
                                              isPublic: true,
                                              mimeType: "image/png",
                                              originalName: assetResources.first?.originalFilename ?? UUID().uuidString,
                                              userGroupHash: thread.userGroupHash,
                                              hC: height,
                                              wC: width
            )
            uploadProfileUniqueId = imageRequest?.uniqueId
        }
        if thread.type?.isPrivate == false, isPublic == false {
            switchToPrivateType()
        } else if thread.type?.isPrivate == true, isPublic == true {
            switchPublicType()
        }
        let req = UpdateThreadInfoRequest(description: threadDescription, threadId: threadId, threadImage: imageRequest, title: editTitle)
        RequestsManager.shared.append(prepend: EDIT_GROUP_KEY, value: req, autoCancel: false)
        ChatManager.activeInstance?.conversation.updateInfo(req)
    }

    public func onEditGroup(_ response: ChatResponse<Conversation>) {
        if response.contains(prepend: EDIT_GROUP_KEY) {
            image = nil
            isLoading = false
            uploadProfileUniqueId = nil
            uploadProfileProgress = nil
            dismiss = true
//            threadVM?.animateObjectWillChange()
        }
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .updatedInfo(let response):
            onEditGroup(response)
        case .changedType(let chatResponse):
            onChangeThreadType(chatResponse)
        case .deleted(let response):
            onDeletedConversation(response)
        default:
            break
        }
    }

    private func onReactionEvent(_ event: ReactionEventTypes) {
        switch event {
        case .customizeReactions(let chatResponse):
            // Update the UI specfically if it was updated by another admin and the switch should be updated.
            if chatResponse.subjectId == thread.id {
                isLoading = false
                delayEnableReactionEventForASecond()
                isReactionsEnabled = chatResponse.result?.reactionStatus != .disable
                animateObjectWillChange()
            }
        default:
            break
        }
    }

    private func onParticipantsEvent(_ event: ParticipantEventTypes) {
        switch event {
        case .participants(let response):
            onAdmins(response)
        default:
            break
        }
    }

    public func switchToPrivateType() {
        AppState.shared.objectsContainer.threadsVM.makeThreadPrivate(thread)
    }

    public func switchPublicType() {
        AppState.shared.objectsContainer.threadsVM.makeThreadPublic(thread)
    }

    public func toggleThreadVisibility() {
        guard let threadId = thread.id, let type = thread.type else { return }
        let typeValue: ThreadTypes = type.isPrivate == true ? type.publicType : type.privateType
        let req = ChangeThreadTypeRequest(threadId: threadId, type: typeValue)
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.conversation.changeType(req)
    }

    private func onChangeThreadType(_ response: ChatResponse<Conversation>) {
        self.threadVM?.thread.type = response.result?.type
        isPublic = thread.type?.isPrivate == false
        if let req = response.pop(prepend: CHANGE_TO_PUBLIC_KEY) as? ChangeThreadTypeRequest {
            threadVM?.thread.uniqueName = req.uniqueName
        }
        animateObjectWillChange()
    }

    public func getAdminsCount() {
        guard let threadId = thread.id else { return }
        let req = ThreadParticipantRequest(request: .init(threadId: threadId, count: 100), admin: true)
        RequestsManager.shared.append(prepend: EDIT_GROUP_ADMINS_KEY, value: req)
        ChatManager.activeInstance?.conversation.participant.get(req)
    }

    private func onAdmins(_ response: ChatResponse<[Participant]>) {
        if !response.cache, response.pop(prepend: EDIT_GROUP_ADMINS_KEY) != nil {
            adminCounts = response.result?.count ?? 0
        }
    }

    private func onDeletedConversation(_ response: ChatResponse<Participant>) {
        if response.subjectId == threadVM?.threadId {
            AppState.shared.objectsContainer.navVM.popAllPaths()
            animateObjectWillChange()
        }
    }

    private func delayEnableReactionEventForASecond() {
        enableReactionEvent = false
        Task {
            try? await Task.sleep(for: .milliseconds(1000))
            enableReactionEvent = true
        }
    }

    deinit{
        print("deinit EditConversationViewModel")
    }
}
