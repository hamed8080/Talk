//
//  MessageRowCalculators.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import SwiftUI
import TalkModels
import Chat
import UIKit

class MessageRowCalculators {
    typealias MessageType = any HistoryMessageProtocol

    class func calculate(message: MessageType, threadVM: ThreadViewModel?, appendMessages: [MessageType] = []) async -> MessageRowCalculatedData {
        var calculatedMessage = MessageRowCalculatedData()
        var sizes = MessageRowSizes()
        var rowType = MessageViewRowType()

        calculatedMessage.isMe = message.isMe(currentUserId: AppState.shared.user?.id) || message is UploadProtocol

        calculatedMessage.canShowIconFile = message.replyInfo?.messageType != .text && message.replyInfo?.deleted == false
        calculatedMessage.isCalculated = true
        calculatedMessage.fileMetaData = message.fileMetaData /// decoding data so expensive if it will happen on the main thread.
        let imageResult = calculateImageSize(message: message, calculatedMessage: calculatedMessage)
        sizes.imageWidth = imageResult?.width
        sizes.imageHeight = imageResult?.height
        calculatedMessage.isReplyImage = calculateIsReplyImage(message: message)
        calculatedMessage.replyLink = calculateReplyLink(message: message)
        sizes.paddings.paddingEdgeInset = calculatePaddings(message: message, calculatedMessage: calculatedMessage)
        calculatedMessage.avatarSplitedCharaters = String.splitedCharacter(message.participant?.name ?? message.participant?.username ?? "")

        calculatedMessage.canEdit = (message.editable == true && calculatedMessage.isMe) || (message.editable == true && threadVM?.thread.admin == true && threadVM?.thread.type?.isChannelType == true)
        rowType.isMap = calculatedMessage.fileMetaData?.mapLink != nil || calculatedMessage.fileMetaData?.latitude != nil || message is UploadFileWithLocationMessage
        let isFirstMessageOfTheUser = await isFirstMessageOfTheUser(message, appended: appendMessages, viewModel: threadVM)
        calculatedMessage.isFirstMessageOfTheUser = threadVM?.thread.group == true && isFirstMessageOfTheUser
        calculatedMessage.isLastMessageOfTheUser = await isLastMessageOfTheUser(message: message, appended: appendMessages, viewModel: threadVM)
        calculatedMessage.isEnglish = message.message?.naturalTextAlignment == .leading
        calculatedMessage.markdownTitle = calculateAttributeedString(message: message)
        rowType.isPublicLink = message.isPublicLink
        rowType.isFile = message.isFileType && !rowType.isMap && !message.isImage && !message.isAudio && !message.isVideo
        rowType.isReply = message.replyInfo != nil
        if let date = message.time?.date {
            calculatedMessage.timeString = MessageRowCalculatedData.formatter.string(from: date)
        }

        rowType.isImage = !rowType.isMap && message.isImage
        rowType.isVideo = message.isVideo
        rowType.isAudio = message.isAudio
        rowType.isForward = message.forwardInfo != nil
        rowType.isUnSent = message.isUnsentMessage
        rowType.hasText = (!rowType.isPublicLink) && calculateText(message: message) != nil
        rowType.cellType = getCellType(message: message, isMe: calculatedMessage.isMe)
        calculatedMessage.callTypeKey = message.callHistory?.status?.key?.bundleLocalized() ?? ""
        async let color = threadVM?.participantsColorVM.color(for: message.participant?.id ?? -1)
        calculatedMessage.participantColor = await color ?? .clear

        calculatedMessage.fileURL = getFileURL(serverURL: message.url)

        calculatedMessage.computedFileSize = calculateFileSize(message: message, calculatedMessage: calculatedMessage)
        calculatedMessage.extName = calculateFileTypeWithExt(message: message, calculatedMessage: calculatedMessage)
        calculatedMessage.fileName = calculateFileName(message: message, calculatedMessage: calculatedMessage)
        calculatedMessage.addOrRemoveParticipantsAttr = calculateAddOrRemoveParticipantRow(message: message, calculatedMessage: calculatedMessage)
        sizes.paddings.textViewPadding = calculateTextViewPadding(message: message)
        calculatedMessage.localizedReplyFileName = calculateLocalizeReplyFileName(message: message)
        calculatedMessage.groupMessageParticipantName = calculateGroupParticipantName(message: message, calculatedMessage: calculatedMessage, thread: threadVM?.thread)
        sizes.replyContainerWidth = await calculateReplyContainerWidth(message: message, calculatedMessage: calculatedMessage, sizes: sizes)
        sizes.forwardContainerWidth = await calculateForwardContainerWidth(rowType: rowType, sizes: sizes)
        calculatedMessage.isInTwoWeekPeriod = calculateIsInTwoWeekPeriod(message: message)
        calculatedMessage.textLayer = getTextLayer(markdownTitle: calculatedMessage.markdownTitle)
        calculatedMessage.textRect = getRect(markdownTitle: calculatedMessage.markdownTitle, width: ThreadViewModel.maxAllowedWidth - 16)

        let originalPaddings = sizes.paddings
        sizes.paddings = calculateSpacingPaddings(message: message, calculatedMessage: calculatedMessage)
        sizes.paddings.textViewPadding = originalPaddings.textViewPadding
        sizes.paddings.paddingEdgeInset = originalPaddings.paddingEdgeInset

        calculatedMessage.avatarColor = String.getMaterialColorByCharCode(str: message.participant?.name ?? message.participant?.username ?? "")
        calculatedMessage.state.isInSelectMode = threadVM?.selectedMessagesViewModel.isInSelectMode ?? false

        calculatedMessage.callDateText = calculateCallText(message: message)

        calculatedMessage.rowType = rowType
        let estimateHeight = calculateEstimatedHeight(calculatedMessage, sizes)
        sizes.estimatedHeight = estimateHeight
        calculatedMessage.sizes = sizes

        return calculatedMessage
    }

    class func calculatePaddings(message: MessageType, calculatedMessage: MessageRowCalculatedData) -> UIEdgeInsets {
        let isReplyOrForward = (message.forwardInfo != nil || message.replyInfo != nil) && !message.isImage
        let tailWidth: CGFloat = 6
        let paddingLeading = isReplyOrForward ? (calculatedMessage.isMe ? 10 : 16) : (calculatedMessage.isMe ? 4 : 4 + tailWidth)
        let paddingTrailing: CGFloat = isReplyOrForward ? (calculatedMessage.isMe ? 16 : 10) : (calculatedMessage.isMe ? 4 + tailWidth : 4)
        let paddingTop: CGFloat = isReplyOrForward ? 10 : 4
        let paddingBottom: CGFloat = 4
        return UIEdgeInsets(top: paddingTop, left: paddingLeading, bottom: paddingBottom, right: paddingTrailing)
    }

    class func calculateTextViewPadding(message: MessageType) -> UIEdgeInsets {
        return UIEdgeInsets(top: !message.isImage && message.replyInfo == nil && message.forwardInfo == nil ? 6 : 0, left: 6, bottom: 0, right: 6)
    }

    class func replySenderWidthWithIconOrImage(replyInfo: ReplyInfo, iconWidth: CGFloat, senderNameWidth: CGFloat) -> CGFloat {
        let space: CGFloat = 1.5 + 32 /// 1.5 bar + 8 for padding + 8 for space between image and leading bar + 8 between image and sender name + 16 for padding
        let senderNameWithImageSize = senderNameWidth + space + iconWidth
        return senderNameWithImageSize
    }

    class func messageContainerTextWidth(text: String, replyWidth: CGFloat, sizes: MessageRowSizes) -> CGFloat {
        let font = UIFont(name: "IRANSansX", size: 14) ?? .systemFont(ofSize: 14)
        let textWidth = text.widthOfString(usingFont: font) + replyWidth
        let minimumWidth: CGFloat = 128
        let maxOriginal = max(minimumWidth, textWidth + sizes.paddings.paddingEdgeInset.left + sizes.paddings.paddingEdgeInset.right)
        return maxOriginal
    }

    class func replySenderWidthCalculation(replyInfo: ReplyInfo) -> CGFloat {
        let senderNameText = replyInfo.participant?.contactName ?? replyInfo.participant?.name ?? ""
        let senderFont = UIFont(name: "IRANSansX-Bold", size: 12) ?? .systemFont(ofSize: 12)
        let senderNameWidth = senderNameText.widthOfString(usingFont: senderFont)
        return senderNameWidth
    }

    class func replyStaticTextWidth() -> CGFloat {
        let staticText = "Message.replyTo".bundleLocalized()
        let font = UIFont(name: "IRANSansX-Bold", size: 12) ?? .systemFont(ofSize: 12)
        let width = staticText.widthOfString(usingFont: font) + 12
        return width
    }

    class func replyIconOrImageWidth(calculatedMessage: MessageRowCalculatedData) -> CGFloat {
        let isReplyImageOrIcon = calculatedMessage.isReplyImage || calculatedMessage.canShowIconFile
        return isReplyImageOrIcon ? 32 : 0
    }

    class func calculateFileSize(message: MessageType, calculatedMessage: MessageRowCalculatedData) -> String? {
        let normal = message as? UploadFileMessage
        let reply = message as? UploadFileWithReplyPrivatelyMessage
        let fileReq = normal?.uploadFileRequest ?? reply?.uploadFileRequest
        let imageReq = normal?.uploadImageRequest ?? reply?.uploadImageRequest
        let size = fileReq?.data.count ?? imageReq?.data.count ?? 0
        let uploadFileSize: Int64 = Int64(size)
        let realServerFileSize = calculatedMessage.fileMetaData?.file?.size
        let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale)?.replacingOccurrences(of: "٫", with: ".")
        return fileSize
    }

    class func calculateFileTypeWithExt(message: MessageType, calculatedMessage: MessageRowCalculatedData) -> String? {
        let normal = message as? UploadFileMessage
        let reply = message as? UploadFileWithReplyPrivatelyMessage
        let fileReq = normal?.uploadFileRequest ?? reply?.uploadFileRequest
        let imageReq = normal?.uploadImageRequest ?? reply?.uploadImageRequest

        let uploadFileType = fileReq?.originalName ?? imageReq?.originalName
        let serverFileType = calculatedMessage.fileMetaData?.file?.originalName
        let split = (serverFileType ?? uploadFileType)?.split(separator: ".")
        let ext = calculatedMessage.fileMetaData?.file?.extension
        let lastSplit = String(split?.last ?? "")
        let extensionName = (ext ?? lastSplit)
        return extensionName.isEmpty ? nil : extensionName.uppercased()
    }

    class func calculateAddOrRemoveParticipantRow(message: MessageType, calculatedMessage: MessageRowCalculatedData) -> NSAttributedString? {
        if ![.participantJoin, .participantLeft].contains(message.type) { return nil }
        let date = Date(milliseconds: Int64(message.time ?? 0)).onlyLocaleTime
        let string = "\(message.addOrRemoveParticipantString(meId: AppState.shared.user?.id) ?? "") \(date)"
        let attr = NSMutableAttributedString(string: string)
        let isMeDoer = "General.you".bundleLocalized()
        let doer = calculatedMessage.isMe ? isMeDoer : (message.participant?.name ?? "")
        let doerRange = NSString(string: string).range(of: doer)
        attr.addAttributes([
            NSAttributedString.Key.foregroundColor: UIColor(named: "accent") ?? .orange,
            NSAttributedString.Key.font: UIFont(name: "IRANSansX", size: 14) ?? .systemFont(ofSize: 14)
        ], range: doerRange)
        return attr
    }

    class func textForContianerCalculation(message: MessageType, calculatedMessage: MessageRowCalculatedData) -> String {
        let fileNameText = calculatedMessage.fileName ?? ""
        let messageText = message.message?.prefix(150).replacingOccurrences(of: "\n", with: " ") ?? ""
        let messageFileText = messageText.count > fileNameText.count ? messageText : fileNameText
        return messageFileText
    }

    class func replyPrimaryMessageFileIconWidth(calculatedMessage: MessageRowCalculatedData) -> CGFloat {
        if calculatedMessage.fileName == nil || calculatedMessage.fileName?.isEmpty == true { return 0 }
        return 32
    }

    class func calculateReplyContainerWidth(message: MessageType, calculatedMessage: MessageRowCalculatedData, sizes: MessageRowSizes) async -> CGFloat? {
        guard let replyInfo = message.replyInfo else { return nil }

        let staticReplyTextWidth = replyStaticTextWidth()
        let text = textForContianerCalculation(message: message, calculatedMessage: calculatedMessage)


        let replyWithIconWidth = replyPrimaryMessageFileIconWidth(calculatedMessage: calculatedMessage)
        let textWidth = messageContainerTextWidth(text: text, replyWidth: replyWithIconWidth, sizes: sizes)

        let iconWidth = replyIconOrImageWidth(calculatedMessage: calculatedMessage)
        let senderNameWidth = replySenderWidthCalculation(replyInfo: replyInfo)

        let senderNameWithIconOrImageInReply = replySenderWidthWithIconOrImage(replyInfo: replyInfo, iconWidth: iconWidth, senderNameWidth: senderNameWidth)
        let maxWidthWithSender = max(textWidth + staticReplyTextWidth, senderNameWithIconOrImageInReply + staticReplyTextWidth)

        if !message.isImage, text.count < 60 {
            return maxWidthWithSender
        } else if !message.isImage, replyInfo.message?.count ?? 0 < text.count {
            let maxAllowedWidth = min(maxWidthWithSender, ThreadViewModel.maxAllowedWidth)
            return maxAllowedWidth
        } else {
            return nil
        }
    }

    class func calculateFileName(message: MessageType, calculatedMessage: MessageRowCalculatedData) -> String? {
        let fileName = calculatedMessage.fileMetaData?.file?.name
        if fileName == "" || fileName == "blob", let originalName = calculatedMessage.fileMetaData?.file?.originalName {
            return originalName
        }
        return fileName ?? message.uploadFileName()?.replacingOccurrences(of: ".\(message.uploadExt() ?? "")", with: "")
    }

    class func calculateForwardContainerWidth(rowType: MessageViewRowType, sizes: MessageRowSizes) async -> CGFloat? {
        if rowType.isMap {
            return sizes.mapWidth - 8
        }
        return .infinity
    }

    class func calculateImageSize(message: MessageType, calculatedMessage: MessageRowCalculatedData) -> CGSize? {
        if message.isImage {
            /// We use max to at least have a width, because there are times that maxWidth is nil.
            let uploadMapSizeWidth = message is UploadFileWithLocationMessage ? Int(DownloadFileManager.emptyImage.size.width) : nil
            let uploadMapSizeHeight = message is UploadFileWithLocationMessage ? Int(DownloadFileManager.emptyImage.size.height) : nil
            let uploadImageReq = (message as? UploadFileMessage)?.uploadImageRequest
            let imageWidth = CGFloat(calculatedMessage.fileMetaData?.file?.actualWidth ?? uploadImageReq?.wC ?? uploadMapSizeWidth ?? 0)
            let maxWidth = ThreadViewModel.maxAllowedWidth
            /// We use max to at least have a width, because there are times that maxWidth is nil.
            let imageHeight = CGFloat(calculatedMessage.fileMetaData?.file?.actualHeight ?? uploadImageReq?.hC ?? uploadMapSizeHeight ?? 0)
            let originalWidth: CGFloat = imageWidth
            let originalHeight: CGFloat = imageHeight
            var designerWidth: CGFloat = maxWidth
            var designerHeight: CGFloat = maxWidth
            let originalRatio: CGFloat = max(0, originalWidth / originalHeight) // To escape nan 0/0 is equal to nan
            let designRatio: CGFloat = max(0, designerWidth / designerHeight) // To escape nan 0/0 is equal to nan
            if originalRatio > designRatio {
                designerHeight = max(0, designerWidth / originalRatio) // To escape nan 0/0 is equal to nan
            } else {
                designerWidth = designerHeight * originalRatio
            }
            let isSquare = originalRatio >= 1 && originalRatio <= 1.5
            var newSizes = CGSize(width: 0, height: 0)
            newSizes.width = isSquare ? designerWidth : min(designerWidth * 1.5, maxWidth)
            newSizes.height = isSquare ? designerHeight : min(designerHeight * 1.5, maxWidth)
            // We do this because if we got NAN as a result of 0 / 0 we have to prepare a value other than zero
            // Because in maxWidth we can not say maxWidth is Equal zero and minWidth is equal 128
            if newSizes.width == 0 {
                newSizes.width = ThreadViewModel.maxAllowedWidth
            }
            return newSizes
        }
        return nil
    }

    class func calculateLocalizeReplyFileName(message: MessageType) -> String? {
        if let message = message.replyInfo?.message?.prefix(150).replacingOccurrences(of: "\n", with: " "), !message.isEmpty {
            return message
        } else if let fileHint = message.replyFileStringName?.bundleLocalized(), !fileHint.isEmpty {
            return fileHint
        } else {
            return nil
        }
    }

    class func calculateIsInTwoWeekPeriod(message: MessageType) -> Bool {
        let twoWeeksInMilliSeconds: UInt = 1_209_600_000
        let now = UInt(Date().millisecondsSince1970)
        let twoWeeksAfter = UInt(message.time ?? 0) + twoWeeksInMilliSeconds
        if twoWeeksAfter > now {
            return true
        }
        return false
    }

    class func calculateGroupParticipantName(message: MessageType, calculatedMessage: MessageRowCalculatedData, thread: Conversation?) -> String? {
        let canShowGroupName = !calculatedMessage.isMe && thread?.group == true && thread?.type?.isChannelType == false
        && calculatedMessage.isFirstMessageOfTheUser
        if canShowGroupName {
            return message.participant?.contactName ?? message.participant?.name
        }
        return nil
    }

    class func calulateReactions(reactions: ReactionInMemoryCopy) async -> ReactionRowsCalculated {
        var rows: [ReactionRowsCalculated.Row] = []
        reactions.summary.forEach { summary in
            let countText = summary.count?.localNumber(locale: Language.preferredLocale) ?? ""
            let emoji = summary.sticker?.emoji ?? ""
            let isMyReaction = reactions.currentUserReaction?.reaction?.rawValue == summary.sticker?.rawValue
            let hasCount = summary.count ?? -1 > 0
            let edgeInset = EdgeInsets(top: hasCount ? 6 : 0,
                                       leading: hasCount ? 8 : 0,
                                       bottom: hasCount ? 6 : 0,
                                       trailing: hasCount ? 8 : 0)
            let selectedEmojiTabId = "\(summary.sticker?.emoji ?? "all") \(countText)"
            rows.append(.init(reactionId: summary.id,
                              edgeInset: edgeInset,
                              sticker: summary.sticker,
                              emoji: emoji,
                              countText: countText,
                              isMyReaction: isMyReaction,
                              hasReaction: hasCount,
                              selectedEmojiTabId: selectedEmojiTabId))
        }

        let topPadding: CGFloat = reactions.summary.count > 0 ? 10 : 0
        let myReactionSticker = reactions.currentUserReaction?.reaction
        return ReactionRowsCalculated(rows: rows, topPadding: topPadding, myReactionSticker: myReactionSticker)
    }

    class func calculateIsReplyImage(message: MessageType) -> Bool {
        if let replyInfo = message.replyInfo {
            return [ChatModels.MessageType.picture, .podSpacePicture].contains(replyInfo.messageType)
        }
        return false
    }

    class func calculateReplyLink(message: MessageType) -> String? {
        if let replyInfo = message.replyInfo {
            let metaData = replyInfo.metadata
            if let data = metaData?.data(using: .utf8), let fileMetaData = try? JSONDecoder.instance.decode(FileMetaData.self, from: data) {
                return fileMetaData.file?.link
            }
        }
        return nil
    }

    class func calculateSpacingPaddings(message: MessageType, calculatedMessage: MessageRowCalculatedData) -> MessagePaddings {
        var paddings = MessagePaddings()
        paddings.textViewSpacingTop = (calculatedMessage.groupMessageParticipantName != nil || message.replyInfo != nil || message.forwardInfo != nil) ? 10 : 0
        paddings.replyViewSpacingTop = calculatedMessage.groupMessageParticipantName != nil ? 10 : 0
        paddings.forwardViewSpacingTop = calculatedMessage.groupMessageParticipantName != nil ? 10 : 0
        paddings.fileViewSpacingTop = (calculatedMessage.groupMessageParticipantName != nil || message.replyInfo != nil || message.forwardInfo != nil) ? 10 : 0
        paddings.radioPadding = UIEdgeInsets(top: 0, left: calculatedMessage.isMe ? 8 : 0, bottom: 8, right: calculatedMessage.isMe ? 8 : 0)
        paddings.mapViewSapcingTop =  (calculatedMessage.groupMessageParticipantName != nil || message.replyInfo != nil || message.forwardInfo != nil) ? 10 : 0
        let hasAlreadyPadding = message.replyInfo != nil || message.forwardInfo != nil
        let padding: CGFloat = hasAlreadyPadding ? 0 : 4
        paddings.groupParticipantNamePadding = .init(top: padding, left: padding, bottom: 0, right: padding)
        return paddings
    }

    class func getCellType(message: MessageType, isMe: Bool) -> CellTypes {
        let type = message.type
        let isUploading = message is UploadProtocol
        let isBareMessage = message.isTextMessageType || message.isUnsentMessage || isUploading
        switch type {
        case .endCall, .startCall:
            return .call
        case .participantJoin, .participantLeft:
            return .participants
        default:
            if message is UnreadMessageProtocol {
                return .unreadBanner
            } else if isMe, isBareMessage {
                return .meMessage
            } else if !isMe, isBareMessage {
                return .partnerMessage
            }
        }
        return .unknown
    }

    class func calculateAttributeedString(message: MessageType) -> NSAttributedString? {
        guard let text = calculateText(message: message) else { return nil }
        let option: AttributedString.MarkdownParsingOptions = .init(allowsExtendedAttributes: false,
                                                                    interpretedSyntax: .inlineOnly,
                                                                    failurePolicy: .throwError,
                                                                    languageCode: nil,
                                                                    appliesSourcePositionAttributes: false)
        guard let mutableAttr = try? NSMutableAttributedString(markdown: text, options: option) else { return NSAttributedString() }
        mutableAttr.addDefaultTextColor(UIColor(named: "text_primary") ?? .white)
        mutableAttr.addUserColor(UIColor(named: "accent") ?? .orange)
        mutableAttr.addLinkColor(UIColor(named: "text_secondary") ?? .gray)
        return NSAttributedString(attributedString: mutableAttr)
    }

    class func calculateText(message: MessageType) -> String? {
        if let uploadReplyTitle = (message as? UploadFileWithReplyPrivatelyMessage)?.replyPrivatelyRequest.replyContent.text  {
            return uploadReplyTitle
        } else if let text = message.message, !text.isEmpty {
            return text
        } else {
            return nil
        }
    }

    class func isLastMessageOfTheUser(message: MessageType, appended: [MessageType], viewModel: ThreadViewModel?) async -> Bool {
        let sections = viewModel?.historyVM.sections
        let index = appended.firstIndex(where: {$0.id == message.id}) ?? -2
        let nextIndex = index + 1
        let isNextExist = appended.indices.contains(nextIndex)
        if appended.count > 0, isNextExist {
            let isSameParticipant = appended[nextIndex].participant?.id == message.participant?.id
            return !isSameParticipant
        } else if sections?.first?.vms.first?.message.participant?.id == message.participant?.id {
            return false
        } else {
            return true
        }
    }

    class func isFirstMessageOfTheUser(_ message: MessageType, appended: [MessageType], viewModel: ThreadViewModel?) async -> Bool {
        let sections = viewModel?.historyVM.sections
        let index = appended.firstIndex(where: {$0.id == message.id}) ?? -2
        let nextIndex = index - 1
        let isNextExist = appended.indices.contains(nextIndex)
        if appended.count > 0, isNextExist {
            let isSameParticipant = appended[nextIndex].participant?.id == message.participant?.id
            return !isSameParticipant
        } else if sections?.first?.vms.first?.message.participant?.id == message.participant?.id {
            return false
        } else {
            return true
        }
    }

    class func calculateCallText(message: MessageType) -> String? {
        if ![.endCall, .startCall].contains(message.type) { return nil }
        guard let time = message.time else { return nil }
        let date = Date(milliseconds: Int64(time))
        let text = date.onlyLocaleTime
        return text
    }

    class func getFileURL(serverURL: URL?) -> URL? {
        if let url = serverURL {
            if ChatManager.activeInstance?.file.isFileExist(url) == false { return nil }
            let fileURL = ChatManager.activeInstance?.file.filePath(url)
            return fileURL
        }
        return nil
    }

    class func getCachedImage(calculatedMessage: MessageRowCalculatedData, isImage: Bool) -> UIImage? {
        if isImage, let url = calculatedMessage.fileURL, let data = try? Data(contentsOf: url) {
            // Full resulation image that has been downloaded before.
            return UIImage(data: data)
        }
        return nil
    }

    class func getTextLayer(markdownTitle: NSAttributedString?) -> CATextLayer? {
        if let attributedString = markdownTitle {
            let textLayer = CATextLayer()
            textLayer.frame.size = getRect(markdownTitle: attributedString, width: ThreadViewModel.maxAllowedWidth)?.size ?? .zero
            textLayer.string = attributedString
            textLayer.backgroundColor = UIColor.clear.cgColor
            textLayer.alignmentMode = .right
            return textLayer
        }
        return nil
    }

    class func getRect(markdownTitle: NSAttributedString?, width: CGFloat) -> CGRect? {
        guard let markdownTitle = markdownTitle else { return nil }
        let ts = NSTextStorage(attributedString: markdownTitle)
        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let tc = NSTextContainer(size: size)
        tc.lineFragmentPadding = 0.0
        let lm = NSLayoutManager()
        lm.addTextContainer(tc)
        ts.addLayoutManager(lm)
        lm.glyphRange(forBoundingRect: CGRect(origin: .zero, size: size), in: tc)
        let rect = lm.usedRect(for: tc)
        return rect
    }

    class func calculateEstimatedHeight(_ calculatedMessage: MessageRowCalculatedData, _ sizes: MessageRowSizes) -> CGFloat {
        if calculatedMessage.rowType.cellType == .call {
            return 32
        } else if calculatedMessage.rowType.cellType == .participants {
            let padding: CGFloat = 16 // top/bottom margin constraint
            let margin: CGFloat = 24 // top/bottom padding label
            let drawableWidth = ThreadViewModel.threadWidth - (margin + padding)
            let height = (getRect(markdownTitle: calculatedMessage.addOrRemoveParticipantsAttr, width: drawableWidth)?.height ?? 0)
            return height + (padding / 2) + (margin / 2)
        }
        let containerMargin: CGFloat = 1
        var estimatedHeight: CGFloat = 0
        let margin: CGFloat = 4 // stack margin
        let spacing: CGFloat = 4

        estimatedHeight += containerMargin
        estimatedHeight += margin

        //group participant name height
        if calculatedMessage.isFirstMessageOfTheUser && !calculatedMessage.isMe {
            estimatedHeight += 16
            estimatedHeight += spacing
        }

        if calculatedMessage.rowType.isReply {
            estimatedHeight += spacing
            estimatedHeight += 48
            estimatedHeight += spacing
        }

        if calculatedMessage.rowType.isForward {
            estimatedHeight += 48
            estimatedHeight += spacing
        }

        if calculatedMessage.rowType.isImage {
            estimatedHeight += sizes.imageHeight ?? 0
            estimatedHeight += spacing
        }

        if calculatedMessage.rowType.isVideo {
            estimatedHeight += 196
            estimatedHeight += spacing
        }

        if calculatedMessage.rowType.isAudio {
            estimatedHeight += 78
            estimatedHeight += spacing
        }

        if calculatedMessage.rowType.isFile {
            estimatedHeight += 44
            estimatedHeight += spacing
        }

        if calculatedMessage.rowType.isMap {
            estimatedHeight += sizes.mapHeight // static inside MessageRowCalculatedData
            estimatedHeight += spacing
        }

        if calculatedMessage.rowType.hasText {
            estimatedHeight += calculatedMessage.textRect?.height ?? 0
            estimatedHeight += spacing
            estimatedHeight += 15 // UITextView margin
        }

        //footer height
        estimatedHeight += 18
        estimatedHeight += margin
        estimatedHeight += containerMargin

        return estimatedHeight
    }
}
