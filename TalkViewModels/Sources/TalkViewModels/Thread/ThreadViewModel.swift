//
//  ThreadViewswift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import MapKit
import Photos
import ChatModels
import TalkModels
import ChatCore
import ChatDTO
import SwiftUI
import OSLog

public struct MessageSection: Identifiable, Hashable, Equatable {
    public var id: Int64 { date.millisecondsSince1970 }
    public let date: Date
    public var vms: ContiguousArray<MessageRowViewModel>

    public init(date: Date, vms: ContiguousArray<MessageRowViewModel>) {
        self.date = date
        self.vms = vms
    }
}

public final class ThreadViewModel: ObservableObject, Identifiable, Hashable {
    public static func == (lhs: ThreadViewModel, rhs: ThreadViewModel) -> Bool {
        rhs.threadId == lhs.threadId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }

    public var thread: Conversation
    public var replyMessage: Message?
    @Published public var dismiss = false
    public var sheetType: ThreadSheetType?
    public var exportMessagesViewModel: ExportMessagesViewModel = .init()
    public var unsentMessagesViewModel: ThreadUnsentMessagesViewModel
    public var uploadMessagesViewModel: ThreadUploadMessagesViewModel
    public var searchedMessagesViewModel: ThreadSearchMessagesViewModel
    public var selectedMessagesViewModel: ThreadSelectedMessagesViewModel = .init()
    public var unreadMentionsViewModel: ThreadUnreadMentionsViewModel
    public var participantsViewModel: ParticipantsViewModel
    public var attachmentsViewModel: AttachmentsViewModel = .init()
    public var mentionListPickerViewModel: MentionListPickerViewModel
    public var sendContainerViewModel: SendContainerViewModel
    public var audioRecoderVM: AudioRecordingViewModel = .init()
    public var scrollVM: ThreadScrollingViewModel = .init()
    public var historyVM: ThreadHistoryViewModel = .init()
    public weak var threadsViewModel: ThreadsViewModel?
    public var participantsColorVM: ParticipantsColorViewModel = .init()
    public var threadPinMessageViewModel: ThreadPinMessageViewModel
    public var readOnly = false
    public var cancelable: Set<AnyCancellable> = []
    public var threadId: Int { thread.id ?? 0 }
    public var signalMessageText: String?
    public var isActiveThread: Bool { AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.viewModel.threadId == threadId }
    public weak var forwardMessage: Message?
    var createThreadCompletion: (()-> Void)?
    public static var threadWidth: CGFloat = 0 {
        didSet {
            // 38 = Avatar width + tail width + leading padding + trailing padding
            maxAllowedWidth = min(400, ThreadViewModel.threadWidth - (38 + MessageRowViewModel.avatarSize))
        }
    }

    public var isSimulatedThared: Bool {
        AppState.shared.appStateNavigationModel.userToCreateThread != nil && thread.id == LocalId.emptyThread.rawValue
    }

    public static var maxAllowedWidth: CGFloat = ThreadViewModel.threadWidth - (38 + MessageRowViewModel.avatarSize)
    var model: AppSettingsModel = .init()
    public var canDownloadImages: Bool = false
    public var canDownloadFiles: Bool = false

    public init(thread: Conversation, readOnly: Bool = false, threadsViewModel: ThreadsViewModel? = nil) {
        self.unsentMessagesViewModel = .init(thread: thread)
        self.uploadMessagesViewModel = .init(thread: thread)
        self.unreadMentionsViewModel = .init(thread: thread)
        self.mentionListPickerViewModel = .init(thread: thread)
        self.sendContainerViewModel = .init(thread: thread)
        self.searchedMessagesViewModel = .init(threadId: thread.id ?? -1)
        self.threadPinMessageViewModel = ThreadPinMessageViewModel(thread: thread)
        self.readOnly = readOnly
        self.thread = thread
        self.threadsViewModel = threadsViewModel
        self.participantsViewModel = ParticipantsViewModel(thread: thread)
        scrollVM.threadVM = self
        historyVM.threadViewModel = self
        setupNotificationObservers()
        setAppSettingsModel()
        selectedMessagesViewModel.threadVM = self
        sendContainerViewModel.threadVM = self
        uploadMessagesViewModel.threadVM = self
        unsentMessagesViewModel.threadVM = self
        exportMessagesViewModel.thread = thread
        historyVM.setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancelable)
        registerNotifications()
        NotificationCenter.appSettingsModel.publisher(for: .appSettingsModel)
            .sink { [weak self] _ in
                self?.setAppSettingsModel()
            }
            .store(in: &cancelable)
    }

    private func setAppSettingsModel() {
        Task { [weak self] in
            guard let self = self else { return }
            model = AppSettingsModel.restore()
            canDownloadImages = canDownloadImagesInConversation()
            canDownloadFiles = canDownloadFilesInConversation()
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if status == .connected && !isSimulatedThared {
            unreadMentionsViewModel.fetchAllUnreadMentions()
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) {
        if thread.id == threadId {
            self.thread.lastMessage = thread.lastMessage
            self.thread.lastMessageVO = thread.lastMessageVO
            setUnreadCount(thread.unreadCount)
            animateObjectWillChange()
        }
    }

    public func onEditedMessage(_ response: ChatResponse<Message>) {
        guard
            let editedMessage = response.result,
            let oldMessage = historyVM.message(for: response.result?.id)?.message
        else { return }
        oldMessage.updateMessage(message: editedMessage)
        updateIfIsPinMessage(editedMessage: editedMessage)
    }

    func updateIfIsPinMessage(editedMessage: Message) {
        if editedMessage.id == thread.pinMessage?.id {
            thread.pinMessage = PinMessage(message: editedMessage)
        }
    }

    public func sendStartTyping(_ newValue: String) {
        if threadId == LocalId.emptyThread.rawValue { return }
        if newValue.isEmpty == false {
            ChatManager.activeInstance?.system.snedStartTyping(threadId: threadId)
        } else {
            ChatManager.activeInstance?.system.sendStopTyping()
        }
    }

    public func sendSignal(_ signalMessage: SignalMessageType) {
        ChatManager.activeInstance?.system.sendSignalMessage(req: .init(signalType: signalMessage, threadId: threadId))
    }

    public func isFirstMessageOfTheUser(_ message: Message) async -> Bool {
        guard let tuples = historyVM.message(for: message.id) else { return false }
        let sectionIndex = tuples.sectionIndex
        let nextIndex = tuples.messageIndex + 1
        let isNextIndexExist = historyVM.sections[sectionIndex].vms.indices.contains(nextIndex)
        if isNextIndexExist {
            let nextMessage = historyVM.sections[sectionIndex].vms[nextIndex]
            return nextMessage.message.participant?.id != message.participant?.id
        }
        return true
    }

    public func isLastMessageOfTheUser(_ message: Message) async -> Bool {
        guard let tuples = historyVM.message(for: message.id) else { return false }
        let sectionIndex = tuples.sectionIndex
        let prevIndex = tuples.messageIndex - 1
        let isPreviousIndexExist = historyVM.sections[sectionIndex].vms.indices.contains(prevIndex)
        if isPreviousIndexExist {
            let prevMessage = historyVM.sections[sectionIndex].vms[prevIndex]
            return prevMessage.message.participant?.id != message.participant?.id
        }
        return true
    }

    public func clearCacheFile(message: Message) {
        if let fileHashCode = message.fileMetaData?.fileHash {
            let path = message.isImage ? Routes.images.rawValue : Routes.files.rawValue
            let url = "\(ChatManager.activeInstance?.config.fileServer ?? "")\(path)/\(fileHashCode)"
            ChatManager.activeInstance?.file.deleteCacheFile(URL(string: url)!)
            NotificationCenter.message.post(.init(name: .message, object: message))
        }
    }

    public func storeDropItems(_ items: [NSItemProvider]) {
        items.forEach { item in
            let name = item.suggestedName ?? ""
            let ext = item.registeredContentTypes.first?.preferredFilenameExtension ?? ""
            let iconName = ext.systemImageNameForFileExtension
            _ = item.loadDataRepresentation(for: .item) { data, _ in
                DispatchQueue.main.async {  [weak self] in
                    let item = DropItem(data: data, name: name, iconName: iconName, ext: ext)
                    self?.attachmentsViewModel.append(attachments: [.init(type: .drop, request: item)])
                    self?.animateObjectWillChange()
                }
            }
        }
    }

    public func onUnreadCount(_ response: ChatResponse<UnreadCount>) {
        if threadId == response.result?.threadId {
            setUnreadCount(response.result?.unreadCount)
            animateObjectWillChange()
        }
    }

    public func setupRecording() {
        audioRecoderVM.threadViewModel = self
        audioRecoderVM.toggle()
        animateObjectWillChange()
    }

    public func setupExportMessage(startDate: Date, endDate: Date) {
        exportMessagesViewModel.objectWillChange
            .sink { [weak self] in
                self?.sheetType = .exportMessagesFile
                self?.animateObjectWillChange()
            }
            .store(in: &cancelable)
        exportMessagesViewModel.exportChats(startDate: startDate, endDate: endDate)
        animateObjectWillChange()
    }

    /// This method prevents to update unread count if the local unread count is smaller than server unread count.
    public func setUnreadCount(_ newCount: Int?) {
        if newCount ?? 0 <= thread.unreadCount ?? 0 {
            thread.unreadCount = newCount
            animateObjectWillChange()
        }
    }

    func onDeleteThread(_ response: ChatResponse<Participant>) {
        if response.subjectId == threadId {
            dismiss = true
        }
    }

    func onLeftThread(_ response: ChatResponse<User>) {
        if response.subjectId == threadId, response.result?.id == AppState.shared.user?.id {
            dismiss = true
        } else {
            thread.participantCount = (thread.participantCount ?? 0) - 1
            animateObjectWillChange()
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if response.result == threadId {
            dismiss = true
        }
    }

    public func moveToFirstUnreadMessage() {
        if let unreadMessage = unreadMentionsViewModel.unreadMentions.first, let time = unreadMessage.time {
            historyVM.moveToTime(time, unreadMessage.id ?? -1, highlight: true)
            unreadMentionsViewModel.setAsRead(id: unreadMessage.id)
            if unreadMentionsViewModel.unreadMentions.count == 0 {
                thread.mentioned = false
                thread.animateObjectWillChange()
                animateObjectWillChange()
            }
        }
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
        exportMessagesViewModel.cancelAllObservers()
        unsentMessagesViewModel.cancelAllObservers()
        uploadMessagesViewModel.cancelAllObservers()
        searchedMessagesViewModel.cancelAllObservers()
        unreadMentionsViewModel.cancelAllObservers()
        participantsViewModel.cancelAllObservers()
        mentionListPickerViewModel.cancelAllObservers()
        sendContainerViewModel.cancelAllObservers()
        historyVM.cancelAllObservers()
        threadPinMessageViewModel.cancelAllObservers()
    }

    func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }

    deinit {
        log("deinit called in class ThreadViewModel: \(self.thread.title ?? "")")
    }
}
