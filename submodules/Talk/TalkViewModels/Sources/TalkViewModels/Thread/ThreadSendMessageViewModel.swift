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

@MainActor
public final class ThreadSendMessageViewModel {
    private weak var viewModel: ThreadViewModel?
    private var creator: P2PConversationBuilder?

    private var thread: Conversation { viewModel?.thread ?? .init() }
    private var threadId: Int { thread.id ?? 0 }
    private var attVM: AttachmentsViewModel { viewModel?.attachmentsViewModel ?? .init() }
    private var uplVM: ThreadUploadMessagesViewModel { viewModel?.uploadMessagesViewModel ?? .init() }
    private var sendVM: SendContainerViewModel { viewModel?.sendContainerViewModel ?? .init() }
    private var selectVM: ThreadSelectedMessagesViewModel { viewModel?.selectedMessagesViewModel ?? .init() }
    private var appState: AppState { AppState.shared }
    private var navModel: AppStateNavigationModel {
        get { appState.appStateNavigationModel }
        set { appState.appStateNavigationModel = newValue }
    }
    private var delegate: ThreadViewDelegate? { viewModel?.delegate }
    private var historyVM: ThreadHistoryViewModel? { viewModel?.historyVM }
    
    private var recorderVM: AudioRecordingViewModel { viewModel?.audioRecoderVM ?? .init() }
    private var model = SendMessageModel(threadId: -1)

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

    /// It triggers when send button tapped
    public func sendTextMessage() async {
        if isOriginForwardThread() { return }
        model = makeModel()
        switch true {
        case navModel.forwardMessageRequest?.threadId == threadId:
            sendForwardMessages()
        case navModel.replyPrivately != nil:
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
            sendNormalMessage()
        }
        
        finalizeMessageSending()
    }
    
    private func finalizeMessageSending() {
        historyVM?.seenVM?.sendSeenForAllUnreadMessages()
        viewModel?.mentionListPickerViewModel.text = ""
        sendVM.clear() // close UI
    }

    private func isOriginForwardThread() -> Bool {
        navModel.forwardMessageRequest != nil && (threadId != navModel.forwardMessageRequest?.threadId)
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
            uplVM.append(uploads)
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
        createConversationIfNeeded { [weak self] in
            guard let self = self else { return }
            
            var uploads = uploadMesasages(isReplyPrivatelyRequest: true)
            
            /// Set ReplyInfo and inner replyPrivatelyInfo before upload to show when we are uploading
            if let replyMessage = navModel.replyPrivately {
                for index in uploads.indices {
                    uploads[index].replyInfo = replyMessage.toReplyInfo
                }
            }
           
            if !uploads.isEmpty {
                /// Append to the messages list while uploading
                uplVM.append(uploads)
            } else {
                guard let req = ReplyPrivatelyRequest(model: model) else { return }
                send(.replyPrivately(req))
            }
            
            /// Clean up and delete file at voicePath
            recorderVM.cancel()
            
            attVM.clear()
            navModel = .init()
            viewModel?.replyMessage = nil
            /// Close Reply UI after reply
            delegate?.showReplyPrivatelyPlaceholder(show: false)
        }
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
        createConversationIfNeeded { [weak self] in
            guard let self = self,
                  let request = UploadFileMessage(audioFileURL: recorderVM.recordingOutputPath, model: model)
            else { return }
            uplVM.append([request])
            recorderVM.cancel()
        }
    }

    private func sendNormalMessage() {
        createConversationIfNeeded {
            Task { [weak self] in
                guard let self = self else { return }
                let (message, request) = Message.makeRequest(model: model)
                await historyVM?.injectMessagesAndSort([message])
                let lastSectionIndex = max(0, (historyVM?.sectionsHolder.sections.count ?? 0) - 1)
                let row = max((historyVM?.sectionsHolder.sections[lastSectionIndex].vms.count ?? 0) - 1, 0)
                let indexPath = IndexPath(row: row, section: lastSectionIndex)
                delegate?.inserted(at: indexPath)
                delegate?.scrollTo(index: indexPath, position: .bottom, animate: true)
                send(.normal(request))
            }
        }
    }

    public func openDestinationConversationToForward(_ destinationConversation: Conversation?, _ contact: Contact?, _ messages: [Message]) {
        /// Close edit mode in ui
        sendVM.clear()
        
        /// Check if we are forwarding to the same thread
        if destinationConversation?.id == threadId || (contact?.userId != nil && contact?.userId == thread.partner) {
            appState.setupForwardRequest(from: threadId, to: threadId, messages: messages)
            delegate?.showMainButtons(true)
            delegate?.showForwardPlaceholder(show: true)
            /// To call the publisher and activate the send button
            viewModel?.sendContainerViewModel.clear()
        } else if let contact = contact {
            appState.openForwardThread(from: threadId, contact: contact, messages: messages)
        } else if let destinationConversation = destinationConversation {
            appState.openForwardThread(from: threadId, conversation: destinationConversation, messages: messages)
        }
        selectVM.clearSelection()
        delegate?.setSelection(false)
    }

    private func sendForwardMessages() {
        guard let req = navModel.forwardMessageRequest else { return }
        if viewModel?.isSimulatedThared == true {
            createAndSend(req)
        } else {
            sendForwardMessages(req)
        }
    }

    private func createAndSend(_ req: ForwardMessageRequest) {
        createConversationIfNeeded { [weak self] in
            guard let self = self else {return}
            let req = ForwardMessageRequest(fromThreadId: req.fromThreadId, threadId: threadId, messageIds: req.messageIds)
            sendForwardMessages(req)
        }
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
                self.navModel = .init()
                self.delegate?.showForwardPlaceholder(show: false)
                self.sendVM.clear()
            }
        }
        sendAttachmentsMessage()
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    public func sendPhotos(_ imageItems: [ImageItem]) {
        createConversationIfNeeded { [weak self] in
            guard let self = self else {return}
            var imageMessages: [UploadFileMessage] = []
            for(index, imageItem) in imageItems.filter({!$0.isVideo}).enumerated() {
                var model = model
                model.uploadFileIndex = index
                let imageMessage = UploadFileMessage(imageItem: imageItem, model: model)
                imageMessages.append(imageMessage)
            }
            uplVM.append(imageMessages)
            sendVideos(imageItems.filter({$0.isVideo}))
            attVM.clear()
        }
    }

    public func sendVideos(_ viedeoItems: [ImageItem]) {
        var videoMessages: [UploadFileMessage] = []
        for (index, item) in viedeoItems.enumerated() {
            var model = model
            model.uploadFileIndex = index
            let videoMessage = UploadFileMessage(videoItem: item, model: model)
            videoMessages.append(videoMessage)
        }
        self.uplVM.append(videoMessages)
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    public func sendFiles(_ urls: [URL]) {
        createConversationIfNeeded { [weak self] in
            guard let self = self else {return}
            var fileMessages: [UploadFileMessage] = []
            for (index, url) in urls.enumerated() {
                let isLastItem = url == urls.last || urls.count == 1
                var model = model
                model.uploadFileIndex = index
                if let fileMessage = UploadFileMessage(url: url, isLastItem: isLastItem, model: model) {
                    fileMessages.append(fileMessage)
                }
            }
            self.uplVM.append(fileMessages)
            attVM.clear()
        }
    }

    public func sendDropFiles(_ items: [DropItem]) {
        createConversationIfNeeded { [weak self] in
            guard let self = self else {return}
            var fileMessages: [UploadFileMessage] = []
            for (index, item) in items.enumerated() {
                var model = model
                model.uploadFileIndex = index
                let fileMessage = UploadFileMessage(dropItem: item, model: model)
                fileMessages.append(fileMessage)
            }
            self.uplVM.append(fileMessages)
            attVM.clear()
        }
    }

    public func sendEditMessage() {
        guard let editMessage = sendVM.getEditMessage(), let messageId = editMessage.id else { return }
        let req = EditMessageRequest(messageId: messageId, model: model)
        send(.edit(req))
    }

    public func sendLocation(_ location: LocationItem) {
        createConversationIfNeeded { [weak self] in
            guard let self = self else {return}
            uplVM.append([UploadFileMessage(location: location, model: model)])
            attVM.clear()
        }
    }

    public func createConversationIfNeeded(completion: @escaping () -> Void) {
        if viewModel?.isSimulatedThared == true {
            createP2PThread(completion)
        } else {
            completion()
        }
    }

    public func createP2PThread(_ completion: @escaping () -> Void) {
        creator = P2PConversationBuilder()
        if let coreuserId = navModel.userToCreateThread?.coreUserId {
            creator?.create(coreUserId: coreuserId) { [weak self] conversation in
                self?.onCreateP2PThread(conversation)
                completion()
                self?.creator = nil
            }
        }
    }

    public func onCreateP2PThread(_ conversation: Conversation) {
        self.viewModel?.updateConversation(conversation)
        DraftManager.shared.clear(contactId: navModel.userToCreateThread?.contactId ?? -1)
        navModel.userToCreateThread = nil
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
                                replyPrivatelyMessage: navModel.replyPrivately
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
}
