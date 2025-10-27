//
//  ThreadDetailViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import SwiftUI
import TalkModels
import TalkExtensions

@MainActor
public final class ThreadDetailViewModel: ObservableObject {
    private(set) var cancellable: Set<AnyCancellable> = []
    public var thread: Conversation?
    public weak var threadVM: ThreadViewModel?
    @Published public var isLoading = false
    public var avatarVM: ImageLoaderViewModel?
    public var canShowEditConversationButton: Bool { thread?.group == true && thread?.admin == true && thread?.type != .selfThread }
    public var participantDetailViewModel: ParticipantDetailViewModel?
    public var editConversationViewModel: EditConversationViewModel?
    private let p2pPartnerFinder = FindPartnerParticipantViewModel()
    public let mutualGroupsVM = MutualGroupViewModel()
    public var scrollViewProxy: ScrollViewProxy?
    @Published public var fullScreenImageLoader: ImageLoaderViewModel
    @Published public var cachedImage: UIImage?
    @Published public var showDownloading: Bool = false
    private var isDismissed = false
    
    // MARK: Computed properties
    
    private var objs: ObjectsContainer { AppState.shared.objectsContainer }
    private var appOverlayVM: AppOverlayViewModel { objs.appOverlayVM }

    public init() {
        let emptyConfig = ImageLoaderConfig(url: "",
                                            size: .ACTUAL,
                                            metaData: thread?.metadata,
                                            userName: String.splitedCharacter(thread?.title ?? ""),
                                            forceToDownloadFromServer: true)
        fullScreenImageLoader = .init(config: emptyConfig)
    }
    
    private func setupFullScreenAvatarConfig() {
        cachedImage = nil
        let config = ImageLoaderConfig(url: imageLink,
                                       size: .ACTUAL,
                                       metaData: thread?.metadata,
                                       userName: String.splitedCharacter(thread?.title ?? ""),
                                       forceToDownloadFromServer: true)
        fullScreenImageLoader.updateCondig(config: config)
    }
    
    private func createImageViewLoadderAndListen() {
        let config = ImageLoaderConfig(url: imageLink,
                                       size: .MEDIUM,
                                       metaData: thread?.metadata,
                                       userName: String.splitedCharacter(thread?.title ?? ""),
                                       forceToDownloadFromServer: true)
        
        avatarVM = ImageLoaderViewModel(config: config)
        avatarVM?.onImage = { [weak self] image in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.cachedImage = image
            }
        }
        avatarVM?.fetch()
    }
    
    private var cachedAvatarVM: ImageLoaderViewModel? {
        let threads = objs.threadsVM.threads + objs.archivesVM.archives
        return threads
            .first(where: { $0.id == threadVM?.thread.id })?.imageLoader as? ImageLoaderViewModel
    }

    public var imageLink: String {
        var image = ""
        if let threadImage = thread?.computedImageURL {
            image = threadImage
        } else if thread?.group == false, let userImage = participantDetailViewModel?.participant.image {
            image = userImage
        }
        return image.replacingOccurrences(of: "http://", with: "https://")
    }
        
    private func onDonwloadAavtarCompleted(image: UIImage) {
        appOverlayVM.galleryImageView = image
        showDownloading = false
        cachedImage = image
    }
    
    public func onTapAvatarAction() {
        // We use cache image because in init fullScreenImageLoader we always set forcetodownload for image to true
        if imageLink.isEmpty { return }
        if cachedImage == nil {
           showDownloading = true
           fullScreenImageLoader.fetch()
        } else {
            appOverlayVM.galleryImageView = cachedImage
        }
    }

    public func setup(threadVM: ThreadViewModel? = nil, participant: Participant? = nil) {
        clear()
        self.thread = threadVM?.thread
        self.threadVM = threadVM

        setupParticipantDetailViewModel(participant: participant)
        setupEditConversationViewModel()
        setupFullScreenAvatarConfig()
        
        avatarVM = cachedAvatarVM
        if avatarVM == nil {
            createImageViewLoadderAndListen()
        }
        
        registerObservers()
        Task { [weak self] in
            await self?.fetchPartnerParticipant()
        }
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .mute(let response):
            onMuteChanged(response)
        case .unmute(let response):
            onUnMuteChanged(response)
        case .deleted(let response):
            onDeleteThread(response)
        case .userRemoveFormThread(let response):
            onUserRemovedByAdmin(response)
        case .closed(let response):
            onClosed(response)
        default:
            break
        }
    }

    public func updateThreadInfo(_ newThread: Conversation) {
        thread = newThread
        
        let imageLoader = ImageLoaderViewModel(conversation: newThread)
        imageLoader.onImage = { [weak self] image in
            Task { @MainActor [weak self] in
                self?.cachedImage = image
            }
        }
        imageLoader.fetch()
        setupFullScreenAvatarConfig()
        animateObjectWillChange()
    }

    private func updateThreadTitle() {
        /// Update thread title inside the thread if we don't have any messages with the partner yet or it's p2p thread so the title of the thread is equal to contactName
        guard let thread = thread else { return }
        if thread.group == false || thread.id ?? 0 == LocalId.emptyThread.rawValue, let contactName = participantDetailViewModel?.participant.contactName {
            threadVM?.setTitle(contactName)
//            threadVM?.animateObjectWillChange()
        }
    }

    public func toggleMute() {
        guard let threadId = thread?.id, threadId != LocalId.emptyThread.rawValue else {
            fakeMuteToggle()
            return
        }
        if thread?.mute ?? false == false {
            mute(threadId)
        } else {
            unmute(threadId)
        }
    }

    private func fakeMuteToggle() {
        if thread?.mute == nil || thread?.mute == false {
            thread?.mute = true
        } else {
            thread?.mute = false
        }
        animateObjectWillChange()
    }

    public func mute(_ threadId: Int) {
        let req = GeneralSubjectIdRequest(subjectId: threadId)
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.mute(req)
        }
    }

    public func unmute(_ threadId: Int) {
        let req = GeneralSubjectIdRequest(subjectId: threadId)
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.unmute(req)
        }
    }

    public func onMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = true
            animateObjectWillChange()
        }
    }

    public func onUnMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = false
            animateObjectWillChange()
        }
    }

    private func onDeleteThread(_ response: ChatResponse<Participant>) {
        if response.subjectId == thread?.id {
            dismissBothDetailAndThreadProgramatically()
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if response.result == thread?.id {
            dismissBothDetailAndThreadProgramatically()
        }
    }

    public func clear() {
        cancelObservers()
        thread = nil
        threadVM = nil
        isLoading = false
        participantDetailViewModel = nil
        editConversationViewModel = nil
    }

    private func registerObservers() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
            .store(in: &cancellable)
        fullScreenImageLoader.$image
            .sink { [weak self] newValue in
                guard let self = self else { return }
                if newValue.size.width > 0, self.cachedImage == nil {
                    onDonwloadAavtarCompleted(image: newValue)
                }
            }
            .store(in: &cancellable)
        
        registerP2PParticipantObserver()
    }

    /// Fetch contact detail of the P2P participant by threadId directly here.
    public func fetchPartnerParticipant() async {
        guard thread?.group == false else { return }
        getP2PPartnerParticipant()
    }

    private func setupParticipantDetailViewModel(participant: Participant?) {
        let partner = threadVM?.participantsViewModel.participants.first(where: {$0.auditor == false && $0.id != AppState.shared.user?.id})
        let threadP2PParticipant = AppState.shared.objectsContainer.navVM.navigationProperties.userToCreateThread
        let participant = participant ?? threadP2PParticipant ?? partner
        if let participant = participant {
            setupP2PParticipant(participant)
        }
    }

    private func setupEditConversationViewModel() {
        if let threadVM = threadVM {
            editConversationViewModel = EditConversationViewModel(threadVM: threadVM)
        }
    }

    public func cancelObservers() {
        cancellable.forEach { cancelable in
            cancelable.cancel()
        }
        participantDetailViewModel?.cancelObservers()
    }

    private func getP2PPartnerParticipant() {
        guard let threadId = thread?.id else { return }
        p2pPartnerFinder.findPartnerBy(threadId: threadId) { [weak self] partner in
            if let self = self, let partner = partner {
                setupP2PParticipant(partner)
                mutualGroupsVM.setPartner(partner)
            }
        }
    }

    private func setupP2PParticipant(_ participant: Participant) {
        participantDetailViewModel = ParticipantDetailViewModel(participant: participant)
        registerP2PParticipantObserver()
    }

    private func registerP2PParticipantObserver() {
        guard let participantDetailViewModel else { return }
        participantDetailViewModel.objectWillChange.sink { [weak self] _ in
            self?.updateThreadTitle()
            /// We have to update the ui all the time and keep it in sync with the ParticipantDetailViewModel.
            self?.animateObjectWillChange()
        }
        .store(in: &cancellable)
        self.animateObjectWillChange()
    }

    private func onClosed(_ response: ChatResponse<Int>) {
        if thread?.id == response.result {
            thread?.closed = true
            animateObjectWillChange()
        }
    }

    deinit {
        let threadName = thread?.computedTitle ?? ""
#if DEBUG
        print("deinit ThreadDetailViewModel title: \(threadName)")
#endif
    }
}

public extension ThreadDetailViewModel {
    func dismissBySwipe() {
        if isDismissed { return }
        isDismissed = true
        threadVM?.scrollVM.disableExcessiveLoading()
        clearObjects()
        
        
        /// In Swipe action we don't remove an item directly from the path, the os will do it itself
        /// we just need to clear out path trackings.
        objs.navVM.popLastPathTracking()
        objs.navVM.popLastDetail()
    }
    
    func dismissByBackButton() {
        if isDismissed { return }
        isDismissed = true
        
        threadVM?.scrollVM.disableExcessiveLoading()
        clearObjects()
        
        objs.navVM.removeDetail(id: threadVM?.thread.id ?? -1)
    }
    
    func dismissBothDetailAndThreadProgramatically() {
        if isDismissed { return }
        isDismissed = true
        
        let threadId = thread?.id
        threadVM?.scrollVM.disableExcessiveLoading()
        clearObjects()
       
        /// Firstly, remove ThreadDetailViewModel path and pop it up.
        objs.navVM.removeDetail(id: threadVM?.thread.id ?? -1)
      
        /// Secondly, remove ThreadViewModel path and pop it up.
        objs.navVM.remove(threadId: threadId)
    }
    
    func dismisByMoveToAMessage() {
        if isDismissed { return }
        isDismissed = true
        
        clearObjects()
       
        /// Firstly, remove ThreadDetailViewModel path and pop it up.
        objs.navVM.removeDetail(id: threadVM?.thread.id ?? -1)
    }
    
    private func clearObjects() {
        objs.contactsVM.editContact = nil
        editConversationViewModel = nil
        participantDetailViewModel = nil
        threadVM = nil
        threadVM?.participantsViewModel.clear()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppState.shared.objectsContainer.navVM.setParticipantToCreateThread(nil)
        }
    }
}
