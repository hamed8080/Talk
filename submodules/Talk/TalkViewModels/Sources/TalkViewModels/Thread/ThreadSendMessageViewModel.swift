//
//  ThreadSendMessageViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation
import UIKit
import TalkExtensions
import TalkModels
import Logger

@MainActor
public final class ThreadSendMessageViewModel {
    private weak var viewModel: ThreadViewModel?

    private var thread: Conversation { viewModel?.thread ?? .init() }
    private var threadId: Int { thread.id ?? 0 }
    private var attVM: AttachmentsViewModel { viewModel?.attachmentsViewModel ?? .init() }
    private var uploadsManager: UploadsManager { appState.objectsContainer.uploadsManager }
    private var sendVM: SendContainerViewModel { viewModel?.sendContainerViewModel ?? .init() }
    private var selectVM: ThreadSelectedMessagesViewModel { viewModel?.selectedMessagesViewModel ?? .init() }
    private var appState: AppState { AppState.shared }
    private var navVM: NavigationModel { AppState.shared.objectsContainer.navVM }
    private var delegate: ThreadViewDelegate? { viewModel?.delegate }
    private var historyVM: ThreadHistoryViewModel? { viewModel?.historyVM }
    
    private var recorderVM: AudioRecordingViewModel { viewModel?.audioRecoderVM ?? .init() }
    private var model = SendMessageModel(threadId: -1)

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }
    
    public func sendTextMessage() async {
        
        /// Move to the bottom of the thread first then send.
        let lastMsg = viewModel?.thread.lastMessageVO
        if let id = lastMsg?.id, let time = lastMsg?.time {
            await viewModel?.historyVM.moveToTime(time, id, highlight: false)
        }
        
        if isOriginForwardThread() { return }
       
        await createP2PThreadIfNeeded()
        await send()
    }

    /// It triggers when send button tapped
    private func send() async {
        model = makeModel()
        
        if !sendVM.getText().isEmpty && attVM.attachments.count > 1 {
            await sendNormalMessage()
            sendVM.clear()
            try? await Task.sleep(for: .seconds(0.5))
            
            /// We have to call makeModel again to create a model without text.
            model = makeModel()
        }
        
        switch true {
        case navVM.navigationProperties.forwardMessageRequest?.threadId == threadId:
            sendForwardMessages()
        case navVM.navigationProperties.replyPrivately != nil:
            sendReplyPrivatelyMessage()
        case viewModel?.replyMessage != nil:
            sendReplyMessage()
        case sendVM.getMode().type == .edit:
            sendEditMessage()
        case attVM.attachments.count > 0:
            sendAttachmentsMessage()
        case recorderVM.recordingOutputPath != nil:
            sendAudiorecording()
        default:
            await sendNormalMessage()
        }
        
        finalizeMessageSending()
    }
    
    private func finalizeMessageSending() {
        historyVM?.seenVM?.sendSeenForAllUnreadMessages()
        viewModel?.mentionListPickerViewModel.text = ""
        sendVM.clear() // close UI
    }

    private func isOriginForwardThread() -> Bool {
        navVM.navigationProperties.forwardMessageRequest != nil && (threadId != navVM.navigationProperties.forwardMessageRequest?.threadId)
    }

    public func sendAttachmentsMessage() {
        let attachments = attVM.attachments

        if let type = attachments.first?.type {
            switch type {
            case .gallery:
                sendPhotos(attachments.compactMap({$0.request as? ImageItem}))
            case .file:
                sendFiles(attachments.compactMap({$0.request as? URL}))
            case .drop:
                sendDropFiles(attachments.compactMap({$0.request as? DropItem}))
            case .map:
                if let location = attachments.first(where: { $0.type == .map })?.request as? LocationItem { sendLocation(location) }
            case .contact:
                // TODO: Implement when server is ready.
                break
            }
        }
    }

    public func sendReplyMessage() {
        var uploads = uploadMesasages(isReplyRequest: true)
        
        /// Set ReplyInfo before upload to show when we are uploading
        if let replyMessage = viewModel?.replyMessage {
            for index in uploads.indices {
                uploads[index].replyInfo = replyMessage.toReplyInfo
            }
        }
                
        if !uploads.isEmpty {
            /// Append to the messages list while uploading
            uploadsManager.enqueue(with: uploads)
        } else {
            send(.reply(ReplyMessageRequest(model: model)))
        }
                
        /// Close Reply UI after reply
        delegate?.openReplyMode(nil)
        
        /// Clean up and delete file at voicePath
        recorderVM.cancel()
        
        attVM.clear()
        viewModel?.replyMessage = nil
    }
    
    public func sendReplyPrivatelyMessage() {
        var uploads = uploadMesasages(isReplyPrivatelyRequest: true)
        
        /// Set ReplyInfo and inner replyPrivatelyInfo before upload to show when we are uploading
        if let replyMessage = navVM.navigationProperties.replyPrivately {
            for index in uploads.indices {
                uploads[index].replyInfo = replyMessage.toReplyInfo
            }
        }
        
        if !uploads.isEmpty {
            /// Append to the messages list while uploading
            uploadsManager.enqueue(with: uploads)
        } else {
            guard let req = ReplyPrivatelyRequest(model: model) else { return }
            send(.replyPrivately(req))
        }
        
        /// Clean up and delete file at voicePath
        recorderVM.cancel()
        
        attVM.clear()
        navVM.resetNavigationProperties()
        viewModel?.replyMessage = nil
        /// Close Reply UI after reply
        delegate?.showReplyPrivatelyPlaceholder(show: false)
    }
    
    private func uploadMesasages (isReplyRequest: Bool = false, isReplyPrivatelyRequest: Bool = false) -> [UploadFileMessage] {
        let attachments = attVM.attachments
        let images = attachments.compactMap({$0.request as? ImageItem})
        let files = attachments.filter{ !($0.request is ImageItem) }.compactMap({$0.request as? URL})
        
        var uploads: [UploadFileMessage] = []
        
        /// Convert recoreded voice to UploadFileMessage
        if let voicePath = recorderVM.recordingOutputPath {
            uploads += [UploadFileMessage(audioFileURL: recorderVM.recordingOutputPath, model: model,isReplyRequest: isReplyRequest, isReplyPrivatelyRequest: isReplyPrivatelyRequest)].compactMap({$0})
        }
        
        /// Convert all images to UploadFileMessage with replyRequest
        uploads += images.compactMap({ UploadFileMessage(imageItem: $0, model: model, isReplyRequest: isReplyRequest, isReplyPrivatelyRequest: isReplyPrivatelyRequest) })
        
        /// Convert all file URL to UploadFileMessage with replyRequest
        uploads += files.compactMap({ UploadFileMessage(url: $0, model: model, isReplyRequest: isReplyRequest, isReplyPrivatelyRequest: isReplyPrivatelyRequest) })
           
        return uploads
    }

    private func sendAudiorecording() {
        guard let request = UploadFileMessage(audioFileURL: recorderVM.recordingOutputPath, model: model)
        else { return }
        uploadsManager.enqueue(with: [request])
        recorderVM.cancel()
    }

    private func sendNormalMessage() async {
        let (message, request) = Message.makeRequest(model: self.model, checkLink: true)
        
        let beforeSectionCount = self.historyVM?.sections.count ?? 0
        
        await self.historyVM?.injectMessagesAndSort([message])
        
        /// Insert new sections if is greater than before secsions count.
        let afterSectionCount = self.historyVM?.sections.count ?? 0
        let sections = afterSectionCount > beforeSectionCount ? IndexSet(beforeSectionCount..<afterSectionCount) : IndexSet()
        
        let lastSectionIndex = max(0, (self.historyVM?.sections.count ?? 0) - 1)
        let row = max((self.historyVM?.sections[lastSectionIndex].vms.count ?? 0) - 1, 0)
        
        let indexPath = IndexPath(row: row, section: lastSectionIndex)
        self.delegate?.inserted(sections, [indexPath], indexPath, .bottom, true)
        self.send(.normal(request))
    }

    public func openDestinationConversationToForward(_ destinationConversation: Conversation?, _ contact: Contact?, _ messages: [Message]) {
        /// Close edit mode in ui
        sendVM.clear()
        
        /// Check if we are forwarding to the same thread
        if destinationConversation?.id == threadId || (contact?.userId != nil && contact?.userId == thread.partner) {
            navVM.setupForwardRequest(from: threadId, to: threadId, messages: messages)
            delegate?.showMainButtons(true)
            delegate?.showForwardPlaceholder(show: true)
            /// To call the publisher and activate the send button
            viewModel?.sendContainerViewModel.clear()
        } else if let contact = contact {
            Task {
                try await navVM.openForwardThread(from: threadId, contact: contact, messages: messages)
            }
        } else if let destinationConversation = destinationConversation {
            navVM.openForwardThread(from: threadId, conversation: destinationConversation, messages: messages)
        }
        selectVM.clearSelection()
        delegate?.setSelection(false)
    }

    private func sendForwardMessages() {
        guard let req = navVM.navigationProperties.forwardMessageRequest else { return }
        if viewModel?.isSimulatedThared == true {
            createAndSend(req)
        } else {
            sendForwardMessages(req)
        }
    }
    
    private func createAndSend(_ req: ForwardMessageRequest) {
        let req = ForwardMessageRequest(fromThreadId: req.fromThreadId, threadId: threadId, messageIds: req.messageIds)
        sendForwardMessages(req)
    }

    private func sendForwardMessages(_ req: ForwardMessageRequest) {
        if !model.textMessage.isEmpty {
            let messageReq = SendTextMessageRequest(threadId: threadId, textMessage: model.textMessage, messageType: .text)
            send(.normal(messageReq))
        }
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.send(.forward(req))
                self.navVM.resetNavigationProperties()
                self.delegate?.showForwardPlaceholder(show: false)
                self.sendVM.clear()
            }
        }
        sendAttachmentsMessage()
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    public func sendPhotos(_ imageItems: [ImageItem]) {
        var imageMessages: [UploadFileMessage] = []
        for(index, imageItem) in imageItems.filter({!$0.isVideo}).enumerated() {
            var model = model
            model.uploadFileIndex = index
            let imageMessage = UploadFileMessage(imageItem: imageItem, model: model)
            imageMessages.append(imageMessage)
        }
        uploadsManager.enqueue(with: imageMessages)
        sendVideos(imageItems.filter({$0.isVideo}))
        attVM.clear()
    }

    public func sendVideos(_ viedeoItems: [ImageItem]) {
        var videoMessages: [UploadFileMessage] = []
        for (index, item) in viedeoItems.enumerated() {
            var model = model
            model.uploadFileIndex = index
            let videoMessage = UploadFileMessage(videoItem: item, model: model)
            videoMessages.append(videoMessage)
        }
        self.uploadsManager.enqueue(with: videoMessages)
    }
    
    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    public func sendFiles(_ urls: [URL]) {
        var fileMessages: [UploadFileMessage] = []
        for (index, url) in urls.enumerated() {
            let isLastItem = url == urls.last || urls.count == 1
            var model = model
            model.uploadFileIndex = index
            if let fileMessage = UploadFileMessage(url: url, isLastItem: isLastItem, model: model) {
                fileMessages.append(fileMessage)
            }
        }
        self.uploadsManager.enqueue(with: fileMessages)
        attVM.clear()
    }

    public func sendDropFiles(_ items: [DropItem]) {
        var fileMessages: [UploadFileMessage] = []
        for (index, item) in items.enumerated() {
            var model = model
            model.uploadFileIndex = index
            let fileMessage = UploadFileMessage(dropItem: item, model: model)
            fileMessages.append(fileMessage)
        }
        self.uploadsManager.enqueue(with: fileMessages)
        attVM.clear()
    }

    public func sendEditMessage() {
        guard let editMessage = sendVM.getEditMessage(), let messageId = editMessage.id else { return }
        let req = EditMessageRequest(messageId: messageId, model: model)
        send(.edit(req))
    }

    public func sendLocation(_ location: LocationItem) {
        uploadsManager.enqueue(with: [UploadFileMessage(location: location, model: model)])
        attVM.clear()
    }
    
    public func createP2PThreadIfNeeded() async {
        if viewModel?.isSimulatedThared == true, let coreUserId = navVM.navigationProperties.userToCreateThread?.coreUserId {
            do {
                let conversation = try await CreateConversationRequester().create(coreUserId: coreUserId)
                onCreateP2PThread(conversation)
            } catch let error as ChatResponse<Sendable> {
                log("Failed to create a p2p conversation: \(error.error?.message ?? "")")
            } catch  {
                log("Failed to create a p2p conversation: \(error.localizedDescription)")
            }
        }
    }

    public func onCreateP2PThread(_ conversation: Conversation) {
        let navVM = AppState.shared.objectsContainer.navVM
        
        if navVM.presentedThreadViewModel?.viewModel.id == LocalId.emptyThread.rawValue {
            viewModel?.thread.id = conversation.id
            viewModel?.id = conversation.id ?? -1
            viewModel?.historyVM.updateThreadId(id: conversation.id ?? -1)
        }
        self.viewModel?.updateConversation(conversation)
        DraftManager.shared.clear(contactId: navVM.navigationProperties.userToCreateThread?.contactId ?? -1)
        navVM.setParticipantToCreateThread(nil)
        // It is essential to fill it again if we create a new conversation, if we don't do that it will send the wrong threadId.
        model.threadId = conversation.id ?? -1
    }

    func makeModel(_ uploadFileIndex: Int? = nil) -> SendMessageModel {
        return SendMessageModel(textMessage: sendVM.getText(),
                                replyMessage: viewModel?.replyMessage,
                                meId: appState.user?.id,
                                conversation: thread,
                                threadId: threadId,
                                userGroupHash: thread.userGroupHash,
                                uploadFileIndex: uploadFileIndex,
                                replyPrivatelyMessage: navVM.navigationProperties.replyPrivately
        )
    }
    
    fileprivate enum SendType {
        case normal(SendTextMessageRequest)
        case reply(ReplyMessageRequest)
        case replyPrivately(ReplyPrivatelyRequest)
        case forward(ForwardMessageRequest)
        case edit(EditMessageRequest)
    }
    
    private func send(_ send: SendType) {
        Task { @ChatGlobalActor in
            guard let message = ChatManager.activeInstance?.message else { return }
            switch send {
            case .normal(let request):
                message.send(request)
                await AppState.shared.objectsContainer.pendingManager.append(uniqueId: request.uniqueId, request: request)
            case .forward(let request):
                message.send(request)
                await AppState.shared.objectsContainer.pendingManager.append(uniqueId: request.uniqueId, request: request)
            case .reply(let request):
                message.reply(request)
                await AppState.shared.objectsContainer.pendingManager.append(uniqueId: request.uniqueId, request: request)
            case .replyPrivately(let request):
                message.replyPrivately(request)
                await AppState.shared.objectsContainer.pendingManager.append(uniqueId: request.uniqueId, request: request)
            case .edit(let request):
                message.edit(request)
                await AppState.shared.objectsContainer.pendingManager.append(uniqueId: request.uniqueId, request: request)
            }
        }
    }
    
    // MARK: Logs
    private func log(_ string: String) {
        Logger.log(title: "ThreadSendMessageViewModel", message: string)
    }
}
