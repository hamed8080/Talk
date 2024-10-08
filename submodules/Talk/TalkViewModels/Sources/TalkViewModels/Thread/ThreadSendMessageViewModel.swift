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
import OSLog

public final class ThreadSendMessageViewModel {
    private weak var viewModel: ThreadViewModel?
    private var creator: P2PConversationBuilder?

    private var thread: Conversation { viewModel?.thread ?? .init() }
    private var threadId: Int { thread.id ?? 0 }
    private var attVM: AttachmentsViewModel { viewModel?.attachmentsViewModel ?? .init() }
    private var uplVM: ThreadUploadMessagesViewModel { viewModel?.uploadMessagesViewModel ?? .init() }
    private var sendVM: SendContainerViewModel { viewModel?.sendContainerViewModel ?? .init() }
    private var selectVM: ThreadSelectedMessagesViewModel { viewModel?.selectedMessagesViewModel ?? .init() }
    private var navModel: AppStateNavigationModel {
        get {
            return AppState.shared.appStateNavigationModel
        } set {
            AppState.shared.appStateNavigationModel = newValue
        }
    }
    private var recorderVM: AudioRecordingViewModel { viewModel?.audioRecoderVM ?? .init() }
    private var model = SendMessageModel(threadId: -1)

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

    /// It triggers when send button tapped
    @MainActor
    public func sendTextMessage() async {
        if isOriginForwardThread() { return }
        model = makeModel()
        if navModel.forwardMessageRequest?.threadId == threadId {
            sendForwardMessages()
        } else if navModel.replyPrivately != nil {
            sendReplyPrivatelyMessage()
        } else if let replyMessage = viewModel?.replyMessage, let replyMessageId = replyMessage.id {
            sendReplyMessage(replyMessageId)
        } else if sendVM.isInEditMessageMode {
            sendEditMessage()
        } else if attVM.attachments.count > 0 {
            sendAttachmentsMessage()
        } else if recorderVM.recordingOutputPath != nil {
            sendAudiorecording()
        } else {
            sendNormalMessage()
        }

        Task { @HistoryActor [weak self] in
            self?.viewModel?.historyVM.seenVM?.sendSeenForAllUnreadMessages()
        }
        viewModel?.mentionListPickerViewModel.text = ""
        sendVM.clear() // close ui
    }

    private func isOriginForwardThread() -> Bool {
        navModel.forwardMessageRequest != nil && (threadId != navModel.forwardMessageRequest?.threadId)
    }

    public func sendAttachmentsMessage() {
        let attchments = attVM.attachments
        let type = attchments.map{$0.type}.first
        let images = attchments.compactMap({$0.request as? ImageItem})
        let urls = attchments.compactMap({$0.request as? URL})
        let location = attchments.first(where: {$0.type == .map})?.request as? LocationItem
        let dropItems = attchments.compactMap({$0.request as? DropItem})
        if type == .gallery {
            sendPhotos(images)
        } else if type == .file {
            sendFiles(urls)
        } else if type == .contact {
            // TODO: It should be implemented whenever the server side is ready.
        } else if type == .map, let item = location {
            sendLocation(item)
        } else if type == .drop {
            sendDropFiles(dropItems)
        }
    }

    public func sendReplyMessage(_ replyMessageId: Int) {
        if attVM.attachments.count == 1 {
            sendSingleReplyAttachment(attVM.attachments.first, replyMessageId)
        } else {
            if attVM.attachments.count > 1 {
                let lastItem = attVM.attachments.last
                if let lastItem {
                    attVM.remove(lastItem)
                }
                sendAttachmentsMessage()
                sendSingleReplyAttachment(lastItem, replyMessageId)
            } else {
                let req = ReplyMessageRequest(model: model)
                ChatManager.activeInstance?.message.reply(req)
            }
        }
        attVM.clear()
        viewModel?.replyMessage = nil
    }

    public func sendSingleReplyAttachment(_ attachmentFile: AttachmentFile?, _ replyMessageId: Int) {
        var req = ReplyMessageRequest(model: model)
        if let imageItem = attachmentFile?.request as? ImageItem {
            let imageReq = UploadImageRequest(imageItem: imageItem, thread.userGroupHash)
            req.messageType = .podSpacePicture
            ChatManager.activeInstance?.message.reply(req, imageReq)
        } else if let url = attachmentFile?.request as? URL, let fileReq = UploadFileRequest(url: url, thread.userGroupHash) {
            req.messageType = .podSpaceFile
            ChatManager.activeInstance?.message.reply(req, fileReq)
        }
    }

    public func sendReplyPrivatelyMessage() {
        send { [weak self] in
            guard let self = self else { return }
            if attVM.attachments.count == 1, let first = attVM.attachments.first {
                sendSingleReplyPrivatelyAttachment(first)
            } else if attVM.attachments.count > 1 {
                sendMultipleAttachemntWithReplyPrivately()
            } else if recorderVM.recordingOutputPath != nil {
                sendReplyPrivatelyWithVoice()
            } else {
                sendTextOnlyReplyPrivately()
            }
            attVM.clear()
            navModel = .init()
            viewModel?.delegate?.showReplyPrivatelyPlaceholder(show: false)
        }
    }

    private func sendMultipleAttachemntWithReplyPrivately() {
        if let lastItem = attVM.attachments.last {
            attVM.remove(lastItem)
            sendAttachmentsMessage()
            sendSingleReplyPrivatelyAttachment(lastItem)
        }
    }

    private func sendTextOnlyReplyPrivately() {
        if let req = ReplyPrivatelyRequest(model: model) {
            ChatManager.activeInstance?.message.replyPrivately(req)
        }
    }

    private func sendSingleReplyPrivatelyAttachment(_ attachmentFile: AttachmentFile) {
        if let imageItem = attachmentFile.request as? ImageItem, let message = UploadFileWithReplyPrivatelyMessage.make(imageItem: imageItem, model: model) {
            uplVM.append([message])
        } else if let message = UploadFileWithReplyPrivatelyMessage.make(attachmentFile: attachmentFile, model: model) {
            uplVM.append([message])
        }
    }

    private func sendReplyPrivatelyWithVoice() {
        if let message = UploadFileWithReplyPrivatelyMessage.make(voiceURL: recorderVM.recordingOutputPath, model: model) {
            uplVM.append([message])
            recorderVM.cancel()
        }
    }

    private func sendAudiorecording() {
        send { [weak self] in
            guard let self = self,
                  let request = UploadFileMessage(audioFileURL: recorderVM.recordingOutputPath, model: model)
            else { return }
            uplVM.append([request])
            recorderVM.cancel()
        }
    }

    private func sendNormalMessage() {
        send {
            Task { [weak self] in
                guard let self = self else { return }
                let tuple = Message.makeRequest(model: model)
                let historyVM = viewModel?.historyVM
                await historyVM?.injectMessagesAndSort([tuple.message])
                let lastSectionIndex = max(0, (historyVM?.sections.count ?? 0) - 1)
                let row = max((historyVM?.sections[lastSectionIndex].vms.count ?? 0) - 1, 0)
                let indexPath = IndexPath(row: row, section: lastSectionIndex)
                viewModel?.delegate?.inserted(at: indexPath)
                viewModel?.delegate?.scrollTo(index: indexPath, position: .bottom, animate: true)
                ChatManager.activeInstance?.message.send(tuple.req)
            }
        }
    }

    public func openDestinationConversationToForward(_ destinationConversation: Conversation?, _ contact: Contact?) {
        sendVM.clear() /// Close edit mode in ui
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let messages = selectVM.getSelectedMessages().compactMap{$0.message as? Message}
            if let contact = contact {
                AppState.shared.openForwardThread(from: threadId, contact: contact, messages: messages)
            } else if let destinationConversation = destinationConversation {
                AppState.shared.openForwardThread(from: threadId, conversation: destinationConversation, messages: messages)
            }
            selectVM.clearSelection()
            viewModel?.delegate?.setSelection(false)
        }
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
        send { [weak self] in
            guard let self = self else {return}
            let req = ForwardMessageRequest(fromThreadId: req.fromThreadId, threadId: threadId, messageIds: req.messageIds)
            sendForwardMessages(req)
        }
    }

    private func sendForwardMessages(_ req: ForwardMessageRequest) {
        if !model.textMessage.isEmpty {
            let messageReq = SendTextMessageRequest(threadId: threadId, textMessage: model.textMessage, messageType: .text)
            ChatManager.activeInstance?.message.send(messageReq)
        }
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            ChatManager.activeInstance?.message.send(req)
            self?.navModel = .init()
            self?.viewModel?.delegate?.showForwardPlaceholder(show: false)
        }
        sendAttachmentsMessage()
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    public func sendPhotos(_ imageItems: [ImageItem]) {
        send { [weak self] in
            guard let self = self else {return}
            var imageMessages: [UploadFileMessage] = []
            for(index, imageItem) in imageItems.filter({!$0.isVideo}).enumerated() {
                var model = model
                model.uploadFileIndex = index
                let imageMessage = UploadFileMessage(imageItem: imageItem, imageModel: model)
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
            let videoMessage = UploadFileMessage(videoItem: item, videoModel: model)
            videoMessages.append(videoMessage)
        }
        self.uplVM.append(videoMessages)
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    public func sendFiles(_ urls: [URL]) {
        send { [weak self] in
            guard let self = self else {return}
            var fileMessages: [UploadFileMessage] = []
            for (index, url) in urls.enumerated() {
                let isLastItem = url == urls.last || urls.count == 1
                var model = model
                model.uploadFileIndex = index
                if let fileMessage = UploadFileMessage(urlItem: url, isLastItem: isLastItem, urlModel: model) {
                    fileMessages.append(fileMessage)
                }
            }
            self.uplVM.append(fileMessages)
            attVM.clear()
        }
    }

    public func sendDropFiles(_ items: [DropItem]) {
        send { [weak self] in
            guard let self = self else {return}
            var fileMessages: [UploadFileMessage] = []
            for (index, item) in items.enumerated() {
                var model = model
                model.uploadFileIndex = index
                let fileMessage = UploadFileMessage(dropItem: item, dropModel: model)
                fileMessages.append(fileMessage)
            }
            self.uplVM.append(fileMessages)
            attVM.clear()
        }
    }

    public func sendEditMessage() {
        guard let editMessage = sendVM.getEditMessage(), let messageId = editMessage.id else { return }
        let req = EditMessageRequest(messageId: messageId, model: model)
        ChatManager.activeInstance?.message.edit(req)
    }

    public func sendLocation(_ location: LocationItem) {
        send { [weak self] in
            guard let self = self else {return}
            let message = UploadFileWithLocationMessage(message: Message(), location: location, model: model)
            uplVM.append([message])
            attVM.clear()
        }
    }

    public func send(completion: @escaping () -> Void) {
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
        let textMessage = sendVM.getText()
        return SendMessageModel(textMessage: textMessage,
                                replyMessage: viewModel?.replyMessage,
                                meId: AppState.shared.user?.id,
                                conversation: thread,
                                threadId: threadId,
                                userGroupHash: thread.userGroupHash,
                                uploadFileIndex: uploadFileIndex,
                                replyPrivatelyMessage: navModel.replyPrivately
        )
    }
}
