//
//  Message+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import TalkModels
import MapKit
import Chat
import SwiftUI

public class MessageHistoryStatics {
    public static let textTypes = [ChatModels.MessageType.text, MessageType.link, MessageType.location]
    public static let imageTypes = [ChatModels.MessageType.podSpacePicture, MessageType.picture]
    public static let audioTypes = [ChatModels.MessageType.voice, .podSpaceSound, .sound, .podSpaceVoice]
    public static let videoTypes = [ChatModels.MessageType.video, .podSpaceVideo, .video]
    public static let fileTypes: [ChatModels.MessageType] = [.voice, .picture, .video, .sound, .file, .podSpaceFile, .podSpacePicture, .podSpaceSound, .podSpaceVoice, .podSpaceVideo]
    public static let unreactionableTypes = [ChatModels.MessageType.endCall, .startCall, .participantJoin, .participantLeft]
    public static let textDirectionMark = Language.isRTL ? "\u{200f}" : "\u{200e}"
    public static let clockImage = UIImage(named: "clock")
    public static let sentImage = UIImage(named: "ic_single_check_mark")
    public static let seenImage = UIImage(named: "ic_double_check_mark")
    public static let leadingTail = UIImage(named: "leading_tail")!
    public static let trailingTail = UIImage(named: "trailing_tail")!
    public static let emptyImage = UIImage(named: "empty_image")!
    public static let audioExtentions = [".mp3", ".aac", ".wav"]
    public static let videoExtentions = [".mp4", ".mov"]
}

public extension HistoryMessageProtocol {
    var forwardMessage: ForwardMessage? { self as? ForwardMessage }
    var forwardCount: Int? { forwardMessage?.forwardMessageRequest.messageIds.count }
    var messageTitle: String { message ?? "" }
    var isPublicLink: Bool { message?.contains(AppRoutes.joinLink) == true }
    var type: ChatModels.MessageType? { messageType ?? .unknown }
    var isTextMessageType: Bool { MessageHistoryStatics.textTypes.contains(messageType ?? .unknown) || isFileType }
    func isMe(currentUserId: Int?) -> Bool { (ownerId ?? 0 == currentUserId ?? 0) || isUnsentMessage }
    /// We should check metadata to be nil. If it has a value, it means that the message file has been successfully uploaded and sent to the chat server.
//    var isUploadMessage: Bool { self is UploadWithTextMessageProtocol && metadata == nil }
    /// Check id because we know that the message was successfully added in server chat.
    var isUnsentMessage: Bool { self is UnSentMessageProtocol && id == nil }

    var isImage: Bool { MessageHistoryStatics.imageTypes.contains(messageType ?? .unknown) || (self as? UploadFileMessage)?.uploadImageRequest != nil }
    var uploadFileRequest: UploadFileRequest? { (self as? UploadFileMessage)?.uploadFileRequest }
    var isAudio: Bool { MessageHistoryStatics.audioTypes.contains(messageType ?? .unknown) || isUploadAudio() }
    var isVideo: Bool { MessageHistoryStatics.videoTypes.contains(messageType ?? .unknown) || isUploadVideo() }
    var reactionableType: Bool { !MessageHistoryStatics.unreactionableTypes.contains(messageType ?? .unknown) }

    var isSelectable: Bool { !MessageHistoryStatics.unreactionableTypes.contains(messageType ?? .unknown) }

    var fileHashCode: String { fileMetaData?.fileHash ?? fileMetaData?.file?.hashCode ?? "" }

    var fileURL: URL? {
        get async {
            guard let url = await url else { return nil }
            return await urlOnChatActor(url: url)
        }
    }
    
    @ChatGlobalActor
    func urlOnChatActor(url: URL) async -> URL? {
        let chat = await ChatManager.activeInstance
        return chat?.file.filePath(url) ?? chat?.file.filePathInGroup(url)
    }

    var url: URL? {
        get async {
            let path = isImage == true ? Routes.images.rawValue : Routes.files.rawValue
            let fileServer = await fileServerOnChatActor()
            let url = "\(fileServer)\(path)/\(fileHashCode)"
            return URL(string: url)
        }
    }
    
    @ChatGlobalActor
    func fileServerOnChatActor() -> String {
        ChatManager.activeInstance?.config.fileServer ?? ""
    }

    var hardLink: URL? {
        get async {
            guard
                let name = fileMetaData?.name,
                let diskURL = await fileURL,
                let ext = fileMetaData?.file?.extension
            else { return nil }
            let hardLink = diskURL.appendingPathComponent(name).appendingPathExtension(ext)
            try? FileManager.default.linkItem(at: diskURL, to: hardLink)
            return hardLink
        }
    }

    var tempURL: URL {
        let originalName = fileMetaData?.file?.originalName /// FileName + Extension
        var name: String? = nil
        if let fileName = fileMetaData?.file?.name, let ext = fileMetaData?.file?.extension {
            name = "\(fileName).\(ext)"
        }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(name ?? originalName ?? "")
        return tempURL
    }

    func makeTempURL() async -> URL? {
        guard
            let diskURL = await fileURL,
            FileManager.default.fileExists(atPath: diskURL.path)
        else { return nil }
        do {
            let data = try Data(contentsOf: diskURL)
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }

    // FIXME: need fix with object decoding in this calss with FileMetaData for proerty metadata    
    var fileMetaData: FileMetaData? {
        guard let metadata = metadata?.data(using: .utf8),
              let metaData = try? JSONDecoder.instance.decode(FileMetaData.self, from: metadata) else { return nil }
        return metaData
    }
    
    var addRemoveParticipant: AddRemoveParticipant? {
        guard messageType == .participantJoin || messageType == .participantLeft,
              let metadata = metadata?.data(using: .utf8) else { return nil }
        return try? JSONDecoder.instance.decode(AddRemoveParticipant.self, from: metadata)
    }

    mutating func updateMessage(message: any HistoryMessageProtocol) {
        deletable = message.deletable ?? deletable
        delivered = message.delivered ?? delivered ?? delivered
        seen = message.seen ?? seen ?? seen
        editable = message.editable ?? editable
        edited = message.edited ?? edited
        id = message.id ?? id
        mentioned = message.mentioned ?? mentioned
        self.message = message.message ?? self.message
        messageType = message.messageType ?? messageType
        metadata = message.metadata ?? metadata
        ownerId = message.ownerId ?? ownerId
        pinned = message.pinned ?? pinned
        previousId = message.previousId ?? previousId
        systemMetadata = message.systemMetadata ?? systemMetadata
        threadId = message.threadId ?? threadId
        time = message.time ?? time
        timeNanos = message.timeNanos ?? timeNanos
        uniqueId = message.uniqueId ?? uniqueId
        conversation = message.conversation ?? conversation
        forwardInfo = message.forwardInfo ?? forwardInfo
        participant = message.participant ?? participant
        replyInfo = message.replyInfo ?? replyInfo
    }

    var iconName: String? {
        messageType?.iconName ?? fileExtIcon
    }

    var fileStringName: String? {
        messageType?.fileStringName
    }

    var replyFileStringName: String? {
        replyInfo?.messageType?.fileStringName
    }

    var replyIconName: String? {
        replyInfo?.messageType?.iconName ?? fileExtIcon
    }

    var fileExtIcon: String {
        (fileMetaData?.file?.extension ?? uploadExt() ?? "").systemImageNameForFileExtension
    }

    var isFileType: Bool {
        return MessageHistoryStatics.fileTypes.contains(messageType ?? .unknown)
    }

    var mapCoordinate: Coordinate? {
        guard
            let array = fileMetaData?.mapLink?.replacingOccurrences(of: Routes.baseMapLink.rawValue, with: "").split(separator: ","),
            let lat = Double(String(array[0])),
            let lng = Double(String(array[1]))
        else { return nil }
        return Coordinate(lat: lat, lng: lng)
    }

    var coordinate: Coordinate? {
        guard let latitude = fileMetaData?.latitude, let longitude = fileMetaData?.longitude else { return nil }
        return Coordinate(lat: latitude, lng: longitude)
    }

    var neshanURL: URL? {
        guard let coordinate = mapCoordinate else { return nil }
        return URL(string: "https://neshan.org/maps/@\(coordinate.lat),\(coordinate.lng),18.1z,0p")
    }

    var appleMapsURL: URL? {
        guard let coordinate = mapCoordinate else { return nil }
        return URL(string: "maps://?q=\(message ?? "")&ll=\(coordinate.lat),\(coordinate.lng)")
    }

    func addOrRemoveParticipantString(meId: Int?) -> String? {
        guard let requestType = addRemoveParticipant?.requestTypeEnum else { return nil }
        let isMe = participant?.id == meId
        let effectedName = addRemoveParticipant?.participnats?.first?.name ?? ""
        let participantName = participant?.name ?? ""
        let effectedParticipantsName = addRemoveParticipant?.participnats?.compactMap{$0.name}.joined(separator: ", ") ?? ""
        switch requestType {
        case .leaveThread:
            return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.left", bundle: Language.preferedBundle, comment: ""), participantName)
        case .joinThread:
            return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.joined", bundle: Language.preferedBundle, comment: ""), participantName)
        case .removedFromThread:
            if isMe {
                return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.removedByMe", bundle: Language.preferedBundle, comment: ""), effectedName)
            } else {
                return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.removed", bundle: Language.preferedBundle, comment: ""), participantName, effectedName)
            }
        case .addParticipant:
            if isMe {
                return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.addedByMe", bundle: Language.preferedBundle, comment: ""), effectedParticipantsName)
            } else {
                return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.added", bundle: Language.preferedBundle, comment: ""), participantName, effectedParticipantsName)
            }
        default:
            return nil
        }
    }

    static func makeRequest(model: SendMessageModel, checkLink: Bool = false) -> (message: Message, req: SendTextMessageRequest) {
        let type = modelMessageType(model.textMessage, checkLink)
        let req = SendTextMessageRequest(threadId: model.threadId,
                                         textMessage: model.textMessage,
                                         messageType: type)
        let message = Message(threadId: model.threadId,
                              message: model.textMessage,
                              messageType: type,
                              ownerId: model.meId,
                              time: UInt(Date().millisecondsSince1970),
                              uniqueId: req.uniqueId,
                              conversation: model.conversation)
        return (message, req)
    }

    static private func modelMessageType(_ textMessage: String, _ checkLink: Bool) ->  ChatModels.MessageType {
        if checkLink {
            return hasLink(textMessage) ? .link : .text
        } else {
            return .text
        }
    }

    static private func hasLink(_ message: String) -> Bool {
        if let linkRegex = NSRegularExpression.urlRegEx {
            let allRange = NSRange(message.startIndex..., in: message)
            return linkRegex.firstMatch(in: message, range: allRange) != nil
        } else {
            return false
        }
    }
    
    func uploadExt() -> String? {
        let fileMessageType = self as? UploadFileMessage
        let uploadfileReq = fileMessageType?.uploadFileRequest
        let uploadImageReq = fileMessageType?.uploadImageRequest
        return uploadImageReq?.fileExtension ?? uploadfileReq?.fileExtension
    }

    func uploadFileName() -> String? {
        let fileMessageType = self as? UploadFileMessage
        let uploadfileReq = fileMessageType?.uploadFileRequest
        let uploadImageReq = fileMessageType?.uploadImageRequest
        return uploadImageReq?.fileName ?? uploadfileReq?.fileName
    }

    func isUploadAudio() -> Bool {
        guard let ext = uploadFileRequest?.fileExtension else { return false }
        return MessageHistoryStatics.audioExtentions.contains(where: {$0 == ext})
    }

    func isUploadVideo() -> Bool {
        guard let ext = uploadFileRequest?.fileExtension else { return false }
        return MessageHistoryStatics.videoExtentions.contains(where: {$0 == ext})
    }

    static var convertedDIRURL: URL? {
        let docDIR = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docDIR?.appending(path: "converted")
    }

    var convertedFileURL: URL? {
        guard let hashCode = fileMetaData?.fileHash ?? fileMetaData?.file?.hashCode else { return nil }
        return Message.convertedDIRURL?.appending(path: "\(hashCode).mp4")
    }
}

public extension Array where Element == Message {
    func sortedByTime() -> [Message] {
        sorted(by: {$0.time ?? 0 < $1.time ?? 0})
    }
}

extension Message: HistoryMessageProtocol {}


public extension Message {
    var toReplyInfo: ReplyInfo {
        .init(deleted: false,
              repliedToMessageId: id,
              message: message,
              messageType: messageType,
              metadata: metadata,
              systemMetadata: systemMetadata,
              repliedToMessageNanos: timeNanos,
              repliedToMessageTime: time,
              participant: participant)
    }
}
