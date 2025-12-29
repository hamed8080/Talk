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

public enum DetailViewTabId: String, Sendable {
    case members = "Memberes"
    case pictures = "Pictures"
    case video = "Video"
    case music = "Music"
    case voice = "Voice"
    case file = "File"
    case link = "Link"
    case mutual = "Mutual"
}

@MainActor
public protocol DetailTabProtocol {
    var title: String { get set }
    var id: DetailViewTabId { get set }
    var viewModel: AnyObject { get set }
}

@MainActor
public class DetailTab: DetailTabProtocol {
    public var title: String
    public var id: DetailViewTabId
    public var viewModel: AnyObject
    
    public init(title: String, id: DetailViewTabId, viewModel: AnyObject) {
        self.title = title
        self.id = id
        self.viewModel = viewModel
    }
}

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
    public var tabs: [DetailTabProtocol] = []
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
        return objs.navVM.allThreads
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
        
        makeTabs()

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
    
    public func updateImageTo(_ image: UIImage?) {
        cachedImage = image
        if let image = image {
            avatarVM?.updateImage(image: image)
        }
    }

    public func updateThreadInfo(_ newThread: Conversation) {
        thread = newThread
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
        guard let thread = thread, thread.group == false || thread.group == nil else { return }
        getP2PPartnerParticipant()
    }

    private func setupParticipantDetailViewModel(participant: Participant?) {
        if threadVM?.thread.group == true { return }
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
        /// Empty fake thread info
        if thread?.id == LocalId.emptyThread.rawValue, let participant = thread?.participants?.first {
            setupP2PParticipant(participant)
            return
        }
        
        /// Real normal thread info.
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

extension ThreadDetailViewModel {
    private func makeTabs() {
        if let thread = thread {
            var tabs: [DetailTabProtocol] = [
                DetailTab(title: "Thread.Tabs.members", id: .members, viewModel: threadVM?.participantsViewModel ?? .init()),
                DetailTab(title: "Thread.Tabs.photos", id: .pictures, viewModel: DetailTabDownloaderViewModel(conversation: thread, messageType: .podSpacePicture, tabName: "Pictures")),
                DetailTab(title: "Thread.Tabs.videos", id: .video, viewModel: DetailTabDownloaderViewModel(conversation: thread, messageType: .podSpaceVideo, tabName: "Video")),
                DetailTab(title: "Thread.Tabs.music",id: .music, viewModel: DetailTabDownloaderViewModel(conversation: thread, messageType: .podSpaceSound, tabName: "Music")),
                DetailTab(title: "Thread.Tabs.voice",id: .voice, viewModel: DetailTabDownloaderViewModel(conversation: thread, messageType: .podSpaceVoice, tabName: "Voice")),
                DetailTab(title: "Thread.Tabs.file", id: .file, viewModel: DetailTabDownloaderViewModel(conversation: thread, messageType: .podSpaceFile, tabName: "File")),
                DetailTab(title: "Thread.Tabs.link", id: .link, viewModel: DetailTabDownloaderViewModel(conversation: thread, messageType: .link, tabName: "Link")),
            ]
            if thread.group == false || thread.group == nil {
                tabs.removeAll(where: {$0.id == .members})
            }
            if thread.group == true, thread.type?.isChannelType == true, (thread.admin == false || thread.admin == nil) {
                tabs.removeAll(where: {$0.id == .members})
            }

            let canShowMutalTab = thread.group == false && thread.type != .selfThread
            if canShowMutalTab {
                tabs.append(DetailTab(title: "Thread.Tabs.mutualgroup", id: .mutual, viewModel: mutualGroupsVM))
            }

            if thread.closed == true {
                tabs.removeAll(where: {$0.id == .members})
            }
            //        if thread.group == true || thread.type == .selfThread || !EnvironmentValues.isTalkTest {
            //            tabs.removeAll(where: {$0.title == "Thread.Tabs.mutualgroup"})
            //        }
            //        self.tabs = tabs

            self.tabs = tabs
        }
    }
}


extension ThreadDetailViewModel {
    public func descriptionString() -> (String, String) {
        /// P2P thread partner bio
        let partnerBio = participantDetailViewModel?.participant.chatProfileVO?.bio ?? "General.noDescription".bundleLocalized()
        
        /// Group thread description
        let groupDescription = thread?.description.validateString ?? "General.noDescription".bundleLocalized()
        
        let isGroup = thread?.group == true
        
        let key = isGroup ? "General.description" : "Settings.bio"
        
        let value = isGroup ? groupDescription : partnerBio
        return (key, value)
    }
}
