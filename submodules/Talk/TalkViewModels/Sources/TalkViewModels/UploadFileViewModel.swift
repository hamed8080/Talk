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
        let message = SendTextMessageRequest(threadId: threadId, textMessage: message.message ?? "", messageType: textMessageType)
        if let fileRequest = (self.message as? UploadFileMessage)?.uploadFileRequest {
            uploadFile(message, fileRequest)
        } else if let fileRequest = (self.message as? UploadFileWithReplyPrivatelyMessage)?.uploadFileRequest {
            uploadFile(message, fileRequest)
        }
    }

    public func startUploadImage() {
        if state == .uploading || state == .completed { return }
        state = .uploading
        guard let threadId = threadId else { return }
        let isImage: Bool = message.isImage
        let textMessageType: ChatModels.MessageType = isImage ? .podSpacePicture : .podSpaceFile
        let message = SendTextMessageRequest(threadId: threadId, textMessage: message.message ?? "", messageType: textMessageType)
        if let imageRequest = (self.message as? UploadFileMessage)?.uploadImageRequest {
            uploadImage(message, imageRequest)
        } else if let uploadLoaction = self.message as? UploadFileWithLocationMessage {
            let req = uploadLoaction
            uploadUniqueId = req.uniqueId
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.message.send(req.locationRequest)
            }
        } else if let imageRequest = (self.message as? UploadFileWithReplyPrivatelyMessage)?.uploadImageRequest {
            uploadImage(message, imageRequest)
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
