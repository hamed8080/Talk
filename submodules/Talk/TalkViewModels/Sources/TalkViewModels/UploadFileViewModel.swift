import Chat
import Combine
import TalkModels
import Foundation

@MainActor
public final class UploadFileViewModel: ObservableObject {
    @Published public private(set) var uploadPercent: Int64 = 0
    @Published public var state: UploadFileState = .paused
    public var message: HistoryMessageType
    var locationThreadId: Int? { message.threadId }
    var threadId: Int? { message.conversation?.id ?? locationThreadId }
    public var uploadUniqueId: String?
    public private(set) var cancelable: Set<AnyCancellable> = []
    public private(set) var fileMetaData: FileMetaData?

    public init(message: HistoryMessageType) {
        self.message = message
        NotificationCenter.upload.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink { [weak self] event in
                self?.onUploadEvent(event)
            }
            .store(in: &cancelable)
    }

    private func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .suspended(let uniqueId):
            onPause(uniqueId)
        case .resumed(let uniqueId):
            onResume(uniqueId)
        case .progress(let uniqueId, let uploadFileProgress):
            onUploadProgress(uniqueId, uploadFileProgress)
        case .completed(let uniqueId, let metaData, let data, let error):
            onCompeletedUpload(uniqueId, metaData, data, error)
        default:
            break
        }
    }

    public func startUploadFile() {
        if state == .uploading || state == .completed { return }
        state = .uploading
        guard let threadId = threadId else { return }
        let isImage: Bool = message.isImage
        let textMessageType: ChatModels.MessageType = isImage ? .podSpacePicture : message.messageType ?? .podSpaceFile
        
        let fileMessage = self.message as? UploadFileMessage
        let fileRequest = fileMessage?.uploadFileRequest
        let replyPrivatelyFileRequest = (self.message as? UploadFileWithReplyPrivatelyMessage)?.uploadFileRequest
        let replyRequest = fileMessage?.replyRequest
        
        let message = SendTextMessageRequest(threadId: threadId, textMessage: message.message ?? "", messageType: textMessageType)
        if replyRequest == nil, let fileRequest = fileRequest {
            uploadFile(message, fileRequest)
        } else if let fileRequest = replyPrivatelyFileRequest {
            uploadFile(message, fileRequest)
        } else if let replyRequest = replyRequest, let fileRequest = fileRequest {
            uploadReplyFile(replyRequest, fileRequest)
        }
    }

    public func startUploadImage() {
        if state == .uploading || state == .completed { return }
        state = .uploading
        guard let threadId = threadId else { return }
        let isImage: Bool = message.isImage
        let textMessageType: ChatModels.MessageType = isImage ? .podSpacePicture : .podSpaceFile
        let message = SendTextMessageRequest(threadId: threadId, textMessage: message.message ?? "", messageType: textMessageType)
        
        let imageMessage = self.message as? UploadFileMessage
        let imageRequest = imageMessage?.uploadImageRequest
        let replyPrivatelyImageRequest = (self.message as? UploadFileWithReplyPrivatelyMessage)?.uploadImageRequest
        let replyRequest = imageMessage?.replyRequest
        
        if replyRequest == nil, let imageRequest = imageRequest {
            uploadImage(message, imageRequest)
        } else if let uploadLoaction = self.message as? UploadFileWithLocationMessage {
            let req = uploadLoaction
            uploadUniqueId = req.uniqueId
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.message.send(req.locationRequest)
            }
        } else if let imageRequest = replyPrivatelyImageRequest {
            uploadImage(message, imageRequest)
        } else if let replyRequest = replyRequest, let imageRequest = imageRequest {
            uploadReplyImage(replyRequest, imageRequest)
        }
    }

    public func uploadFile(_ message: SendTextMessageRequest, _ uploadFileRequest: UploadFileRequest) {
        uploadUniqueId = uploadFileRequest.uniqueId
        if let uploadMessage = self.message as? UploadFileWithReplyPrivatelyMessage {
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.message.replyPrivately(uploadMessage.replyPrivatelyRequest, uploadFileRequest)
            }
        } else {
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.message.send(message, uploadFileRequest)
            }
        }
    }

    public func uploadReplyFile(_ replyRequest: ReplyMessageRequest, _ uploadFileRequest: UploadFileRequest) {
        uploadUniqueId = uploadFileRequest.uniqueId
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.reply(replyRequest, uploadFileRequest)
        }
    }
    
    public func uploadReplyImage(_ replyRequest: ReplyMessageRequest, _ uploadFileRequest: UploadImageRequest) {
        uploadUniqueId = uploadFileRequest.uniqueId
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.reply(replyRequest, uploadFileRequest)
        }
    }

    public func uploadImage(_ message: SendTextMessageRequest, _ uploadImageRequest: UploadImageRequest) {
        uploadUniqueId = uploadImageRequest.uniqueId
        if let uploadMessage = self.message as? UploadFileWithReplyPrivatelyMessage {
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.message.replyPrivately(uploadMessage.replyPrivatelyRequest, uploadImageRequest)
            }
        } else {
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.message.send(message, uploadImageRequest)
            }
        }
    }

    private func onUploadProgress(_ uniqueId: String, _ uploadFileProgress: UploadFileProgress?) {
        if uniqueId == uploadUniqueId {
            uploadPercent = uploadFileProgress?.percent ?? 0
        }
    }

    private func onCompeletedUpload(_ uniqueId: String, _ metaData: FileMetaData?, _ data: Data?, _ error: Error?) {
        self.fileMetaData = metaData
        if uniqueId == uploadUniqueId {
            state = .completed
        }
    }

    public func pauseUpload() {
        guard let uploadUniqueId = uploadUniqueId else { return }
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.file.manageUpload(uniqueId: uploadUniqueId, action: .suspend)
        }
    }

    public func cancelUpload() {
        guard let uploadUniqueId = uploadUniqueId else { return }
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.file.manageUpload(uniqueId: uploadUniqueId, action: .cancel)
        }
    }

    private func onPause(_ uniqueId: String) {
        if uniqueId == uploadUniqueId {
            state = .paused
        }
    }

    public func resumeUpload() {
        guard let uploadUniqueId = uploadUniqueId else { return }
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.file.manageUpload(uniqueId: uploadUniqueId, action: .resume)
        }
    }

    private func onResume(_ uniqueId: String) {
        if uniqueId == uploadUniqueId {
            state = .uploading
        }
    }
}
