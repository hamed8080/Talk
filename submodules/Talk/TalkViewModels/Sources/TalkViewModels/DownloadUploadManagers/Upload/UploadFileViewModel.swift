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
    private var pending: (sendRequest: SendTextMessageRequest, fileMessage: UploadFileMessage)?
    
    public init(message: HistoryMessageType) {
        self.message = message
        NotificationCenter.upload.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink { [weak self] event in
                self?.onUploadEvent(event)
            }
            .store(in: &cancelable)
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancelable)
    }
    
    private func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .suspended(let uniqueId): updateState(uniqueId, to: .paused)
        case .resumed(let uniqueId): updateState(uniqueId, to: .uploading)
        case .progress(let uniqueId, let uploadFileProgress): updateProgress(uniqueId, uploadFileProgress)
        case .completed(let uniqueId, let metaData, let _, let _): uploadCompleted(uniqueId, metaData)
        default: break
        }
    }
    
    public func startUpload() {
        guard state != .uploading, state != .completed, let threadId = threadId, let fileMessage = message as? UploadFileMessage else { return }
        state = .uploading
        
        let textMessageType: ChatModels.MessageType = message.isImage ? .podSpacePicture : (message.messageType ?? .podSpaceFile)
        let sendRequest = SendTextMessageRequest(threadId: threadId, textMessage: message.message ?? "", messageType: textMessageType)
        self.pending = (sendRequest, fileMessage)
        handleFileUpload(for: fileMessage, sendRequest: sendRequest)
    }
    
    private func handleFileUpload(for fileMessage: UploadFileMessage, sendRequest: SendTextMessageRequest) {
        if let request = fileMessage.uploadFileRequest {
            uploadUniqueId = request.uniqueId
            if let replyPrivately = fileMessage.replyPrivatelyRequest {
                upload(.replyPrivatelyFile(replyPrivately, request))
            } else if let reply = fileMessage.replyRequest {
                upload(.replyFile(reply, request))
            } else {
                upload(.file(sendRequest, request))
            }
        } else if let request = fileMessage.uploadImageRequest {
            uploadUniqueId = request.uniqueId
            if let replyPrivately = fileMessage.replyPrivatelyRequest {
                upload(.replyPrivatelyImage(replyPrivately, request))
            } else if let reply = fileMessage.replyRequest {
                upload(.replyImage(reply, request))
            } else {
                upload(.image(sendRequest, request))
            }
        } else if let locationRequest = fileMessage.locationRequest {
            uploadUniqueId = locationRequest.uniqueId
            upload(.location(locationRequest))
        }
    }
    
    private func updateProgress(_ uniqueId: String, _ uploadFileProgress: UploadFileProgress?) {
        if uniqueId == uploadUniqueId {
            uploadPercent = uploadFileProgress?.percent ?? 0
        }
    }
    
    private func uploadCompleted(_ uniqueId: String, _ metaData: FileMetaData?) {
        self.fileMetaData = metaData
        if uniqueId == uploadUniqueId {
            state = .completed
            pending = nil
        }
    }
    
    private func updateState(_ uniqueId: String, to newState: UploadFileState) {
        if uniqueId == uploadUniqueId {
            state = newState
        }
    }
    
    public func action(_ action: DownloaUploadAction) {
        guard let uploadUniqueId = uploadUniqueId else { return }
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.file.manageUpload(uniqueId: uploadUniqueId, action: action)
        }
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
    
    private func onConnectionStatusChanged(_ status: ConnectionStatus) {
        if status == .connected, let pending = pending {
            handleFileUpload(for: pending.fileMessage, sendRequest: pending.sendRequest)
        }
    }
}
