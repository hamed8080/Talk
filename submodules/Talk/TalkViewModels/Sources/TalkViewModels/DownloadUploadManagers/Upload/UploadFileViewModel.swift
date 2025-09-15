import Chat
import Combine
import TalkModels
import Foundation
import Logger

@MainActor
public final class UploadFileViewModel: ObservableObject {
    @Published public private(set) var uploadPercent: Int64 = 0
    @Published public var state: UploadFileState = .undefined
    public var message: HistoryMessageType
    var locationThreadId: Int? { message.threadId }
    var threadId: Int? { message.conversation?.id ?? locationThreadId }
    public var uploadUniqueId: String?
    public private(set) var cancelable: Set<AnyCancellable> = []
    public private(set) var fileMetaData: FileMetaData?
    public private(set) var fileSizeString: String = ""
    public private(set) var fileNameString: String = ""
    public var retryCount = 0
    public var userCanceled = false
    
    public init(message: HistoryMessageType) async {
        self.message = message
        fileSizeString = (message as? UploadFileMessage)?.fileSize?.toSizeStringShort(locale: Language.preferredLocale) ?? ""
        fileNameString = (message as? UploadFileMessage)?.fileName ?? message.messageTitle
        uploadUniqueId = (message as? UploadFileMessage)?.uploadRequestUniuqeId
        setupSubscriptions()
    }
    
    private func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .suspended(let uniqueId): updateState(uniqueId, to: .paused)
        case .resumed(let uniqueId): updateState(uniqueId, to: .uploading)
        case .progress(let uniqueId, let uploadFileProgress): updateProgress(uniqueId, uploadFileProgress)
        case .completed(let uniqueId, let metaData, let _, let _): uploadCompleted(uniqueId, metaData)
        case .failed(let uniqueId, let error): uploadFailed(uniqueId, error)
        case .canceled(let uniqueId): uploadCanceled(uniqueId)
        default: break
        }
    }
    
    public func startUpload() {
        guard state != .uploading, state != .completed, let threadId = threadId, let fileMessage = message as? UploadFileMessage else { return }
        state = .uploading
        handleFileUpload(for: fileMessage, sendRequest: normalTextMessageRequest)
    }
    
    private func handleFileUpload(for fileMessage: UploadFileMessage, sendRequest: SendTextMessageRequest) {
        if let request = fileMessage.uploadFileRequest {
            if let replyPrivately = fileMessage.replyPrivatelyRequest {
                upload(.replyPrivatelyFile(replyPrivately, request))
            } else if let reply = fileMessage.replyRequest {
                upload(.replyFile(reply, request))
            } else {
                upload(.file(sendRequest, request))
            }
        } else if let request = fileMessage.uploadImageRequest {
            if let replyPrivately = fileMessage.replyPrivatelyRequest {
                upload(.replyPrivatelyImage(replyPrivately, request))
            } else if let reply = fileMessage.replyRequest {
                upload(.replyImage(reply, request))
            } else {
                upload(.image(sendRequest, request))
            }
        } else if let locationRequest = fileMessage.locationRequest {
            upload(.location(locationRequest))
        }
    }
    
    private func updateProgress(_ uniqueId: String, _ uploadFileProgress: UploadFileProgress?) {
        if uniqueId == uploadUniqueId {
            uploadPercent = uploadFileProgress?.percent ?? 0
            log("file upload progress :\(uploadFileProgress?.percent ?? 0) for uniqueId: \(uniqueId)")
        }
    }
    
    private func uploadCompleted(_ uniqueId: String, _ metaData: FileMetaData?) {
        self.fileMetaData = metaData
        log("file upload completed for uniqueId: \(uniqueId)")
    }
    
    private func uploadFailed(_ uniqueId: String, _ error: ChatError?) {
        if uniqueId == uploadUniqueId {
            state = .error
            log("file upload failed for uniqueId: \(uniqueId) with error message: \(error?.message) and error code: \(error?.code ?? 0)")
        }
    }
    
    private func updateState(_ uniqueId: String, to newState: UploadFileState) {
        if uniqueId == uploadUniqueId {
            state = newState
            log("file upload state changed to :\(newState) for uniqueId: \(uniqueId)")
        }
    }
    
    private func uploadCanceled(_ uniqueId: String) {
        if uniqueId == uploadUniqueId {
            log("file upload canceled for uniqueId: \(uniqueId)")
        }
    }
    
    public func action(_ action: DownloaUploadAction) {
        guard let uploadUniqueId = uploadUniqueId else { return }
        state = .paused
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.file.manageUpload(uniqueId: uploadUniqueId, action: action)
        }
    }
    
    public func reUpload() {
        if retryCount > 3 {
            return
        }
        retryCount += 1
        action(.cancel)
        startUpload()
    }
    
    fileprivate enum SendType {
        case image(SendTextMessageRequest, UploadImageRequest)
        case file(SendTextMessageRequest, UploadFileRequest)
        case replyImage(ReplyMessageRequest, UploadImageRequest)
        case replyFile(ReplyMessageRequest, UploadFileRequest)
        case replyPrivatelyImage(ReplyPrivatelyRequest, UploadImageRequest)
        case replyPrivatelyFile(ReplyPrivatelyRequest, UploadFileRequest)
        case location(LocationMessageRequest)
    }
    
    private func upload(_ send: SendType) {
        Task { @ChatGlobalActor in
            guard let messageManager = ChatManager.activeInstance?.message else { return }
            switch send {
            case .image(let message, let imageReq): messageManager.send(message, imageReq)
            case .file(let message, let fileReq): messageManager.send(message, fileReq)
            case .replyImage(let replyRequest, let imageReq): messageManager.reply(replyRequest, imageReq)
            case .replyFile(let replyRequest, let fileReq): messageManager.reply(replyRequest, fileReq)
            case .replyPrivatelyImage(let replyPrivatelyRequest, let imageReq): messageManager.replyPrivately(replyPrivatelyRequest, imageReq)
            case .replyPrivatelyFile(let replyPrivatelyRequest, let fileReq): messageManager.replyPrivately(replyPrivatelyRequest, fileReq)
            case .location(let request): messageManager.send(request)
            }
        }
    }
    
    private func log(_ string: String) {
        Logger.log(title: "UploadFileViewModel", message: string, persist: false)
    }
}

// MARK: On ban error
extension UploadFileViewModel {
    
    fileprivate enum SendTypeTextWithMetadata {
        case image(SendTextMessageRequest)
        case file(SendTextMessageRequest)
        case replyImage(ReplyMessageRequest)
        case replyFile(ReplyMessageRequest)
        case replyPrivately(ReplyPrivatelyRequest)
        case location(LocationMessageRequest)
    }
    
    private func onError(_ error: ChatError) {
        if let banError = error.banError, let uniqueId = uploadUniqueId, let duration = banError.duration {
            Task {
                try? await Task.sleep(for: .milliseconds(Double(duration) + 1000.0))
                sendMessageOnBanned()
            }
        }
    }
    
    private func sendTextMessageWithMetadata(_ send: SendTypeTextWithMetadata) {
        Task { @ChatGlobalActor in
            guard let messageManager = ChatManager.activeInstance?.message else { return }
            switch send {
            case .image(let message): messageManager.send(message)
            case .file(let message): messageManager.send(message)
            case .replyImage(let replyRequest): messageManager.reply(replyRequest)
            case .replyFile(let replyRequest): messageManager.reply(replyRequest)
            case .replyPrivately(let replyPrivatelyRequest): messageManager.replyPrivately(replyPrivatelyRequest)
            case .location(let request): messageManager.send(request)
            }
        }
    }
    
    private func sendMessageOnBanned() {
        guard
            let metaData = fileMetaData?.string,
            let uniqueId = uploadUniqueId,
            let fileMessage = message as? UploadFileMessage
        else { return }
        handleSendWithMetadata(for: fileMessage, uniqueId: uniqueId, metadata: metaData)
    }
    
    /// Bound the upload uniqueId to the text message again,
    /// it will happen automatiaclly inside the Chat SDK, though in this case the send failed by ban
    private func handleSendWithMetadata(for fileMessage: UploadFileMessage, uniqueId: String, metadata: String) {
        
        if let request = fileMessage.uploadFileRequest {
            if var replyPrivately = fileMessage.replyPrivatelyRequest {
                replyPrivately.uniqueId = uniqueId
                replyPrivately.metadata = metadata
                sendTextMessageWithMetadata(.replyPrivately(replyPrivately))
            } else if var reply = fileMessage.replyRequest {
                reply.uniqueId = uniqueId
                reply.metadata = metadata
                sendTextMessageWithMetadata(.replyFile(reply))
            } else {
                var normalTextMessageRequest = normalTextMessageRequest
                normalTextMessageRequest.uniqueId = uniqueId
                normalTextMessageRequest.metadata = metadata
                sendTextMessageWithMetadata(.file(normalTextMessageRequest))
            }
        } else if let request = fileMessage.uploadImageRequest {
            if var replyPrivately = fileMessage.replyPrivatelyRequest {
                replyPrivately.uniqueId = uniqueId
                replyPrivately.metadata = metadata
                sendTextMessageWithMetadata(.replyPrivately(replyPrivately))
            } else if var reply = fileMessage.replyRequest {
                reply.uniqueId = uniqueId
                reply.metadata = metadata
                sendTextMessageWithMetadata(.replyImage(reply))
            } else {
                var normalTextMessageRequest = normalTextMessageRequest
                normalTextMessageRequest.uniqueId = uniqueId
                normalTextMessageRequest.metadata = metadata
                sendTextMessageWithMetadata(.image(normalTextMessageRequest))
            }
        } else if let locationRequest = fileMessage.locationRequest {
            sendTextMessageWithMetadata(.location(locationRequest))
        }
    }
}

extension UploadFileViewModel {
    private func setupSubscriptions() {
        NotificationCenter.upload.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink { [weak self] event in
                self?.onUploadEvent(event)
            }
            .store(in: &cancelable)
        
        NotificationCenter.error.publisher(for: .error)
            .compactMap { $0.object as? ChatResponse<any Sendable> }
            .filter { $0?.uniqueId == self.uploadUniqueId }
            .compactMap { $0?.error }
            .sink { [weak self] error in
                Task { @MainActor [weak self] in
                    self?.onError(error)
                }
            }
            .store(in: &cancelable)
        
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                if case .sent(let resp) = event, let uniqueId = self?.uploadUniqueId, resp.uniqueId == uniqueId {
                    Task { [weak self] in
                        self?.setStateToCompleteAfterDeliverResponse()
                    }
                }
            }
            .store(in: &cancelable)
    }
    
    private func setStateToCompleteAfterDeliverResponse() {
        state = .completed
        log("file has been uploaded completely and delivered sucessfully also set state to .completed for uniqueId: \(uploadUniqueId ?? "")")
    }
    
    private var normalTextMessageRequest: SendTextMessageRequest {
        let textMessageType: ChatModels.MessageType = message.isImage ? .podSpacePicture : (message.messageType ?? .podSpaceFile)
        let sendRequest = SendTextMessageRequest(threadId: threadId ?? -1, textMessage: message.message ?? "", messageType: textMessageType)
        return sendRequest
    }
}
