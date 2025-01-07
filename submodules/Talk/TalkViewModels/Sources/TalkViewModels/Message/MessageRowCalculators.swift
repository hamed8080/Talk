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

public struct MainRequirements: Sendable {
    let appUserId: Int?
    let thread: Conversation?
    let participantsColorVM: ParticipantsColorViewModel?
    let isInSelectMode: Bool
    
    public init(appUserId: Int?, thread: Conversation?, participantsColorVM: ParticipantsColorViewModel?, isInSelectMode: Bool) {
        self.appUserId = appUserId
        self.thread = thread
        self.participantsColorVM = participantsColorVM
        self.isInSelectMode = isInSelectMode
    }
}

struct CalculatedDataResult {
    var calData: MessageRowCalculatedData
    var message: HistoryMessageType
}

//@HistoryActor
class MessageRowCalculators {
    
    
    class func batchCalulate(_ messages: [HistoryMessageType],
                             mainData: MainRequirements,
                             viewModel: ThreadViewModel?) async -> [MessageRowViewModel] {
        // 1- accumulate all data needed from the main thread
        guard let viewModel = await viewModel else { return [] }
        
        // 2- Caculate All messages first concurrently withouth need to use a specific Thread / Actor
        var msgsCal = await calculateWithGroup(messages, mainData)
        
        // 3- Calculate fileURL which requires ChatGlobalActor and participantColor where it requires HistoryActor
        for (index, msgCal) in msgsCal.enumerated() {
            let newData = await calculateColorAndFileURL(mainData: mainData,
                                                         message: msgCal.message,
                                                         calculatedMessage: msgCal.calData)
            msgsCal[index].calData = newData
        }
        
        
        let viewModels = createViewModels(msgsCal, viewModel)
        return viewModels
    }
    
    private class func calculateWithGroup(_ messages: [HistoryMessageType], _ mainData: MainRequirements) async -> [CalculatedDataResult] {
        let msgsCal = await withTaskGroup(of: CalculatedDataResult.self) { group in
            for message in messages {
                group.addTask {
                    let calculatedData = calculate(message: message, mainData: mainData, appendMessages: messages)
                    return CalculatedDataResult(calData: calculatedData, message: message)
                }
            }
            var messagesCalculateData: [CalculatedDataResult] = []
            for await vm in group {
                messagesCalculateData.append(vm)
            }
            return (messagesCalculateData)
        }
        return msgsCal
    }
    
    private class func createViewModels(_ msgsCal: [CalculatedDataResult], _ viewModel: ThreadViewModel) -> [MessageRowViewModel] {
        var viewModels: [MessageRowViewModel] = []
        for msgCal in msgsCal {
            let vm = MessageRowViewModel(message: msgCal.message, viewModel: viewModel)
            vm.calMessage = msgCal.calData
            if vm.calMessage.fileURL != nil {
                let fileState = completionFileState(vm.fileState, msgCal.message.iconName)
                vm.setFileStateNonIsloated(fileState)
            }
            viewModels.append(vm)
        }
        return viewModels
    }
    
    private class func completionFileState(_ oldState: MessageFileState, _ iconName: String?) -> MessageFileState {
        var fileState = oldState
        fileState.state = .completed
        fileState.showDownload = false
        fileState.iconState = iconName?.replacingOccurrences(of: ".circle", with: "") ?? ""
        return fileState
    }

   nonisolated class func calculate(message: HistoryMessageType,
                         mainData: MainRequirements,
                         appendMessages: [HistoryMessageType] = []
    ) -> MessageRowCalculatedData {
        var calculatedMessage = MessageRowCalculatedData()
        var sizes = MessageRowSizes()
        var rowType = MessageViewRowType()
        let thread = mainData.thread

        calculatedMessage.isMe = message.isMe(currentUserId: mainData.appUserId) || message is UploadProtocol

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

        let isEditableOrNil = (message.editable == true || message.editable == nil)
        calculatedMessage.canEdit = ( isEditableOrNil && calculatedMessage.isMe) || (isEditableOrNil && thread?.admin == true && thread?.type?.isChannelType == true)
        rowType.isMap = calculatedMessage.fileMetaData?.mapLink != nil || calculatedMessage.fileMetaData?.latitude != nil || message is UploadFileWithLocationMessage
        let isFirstMessageOfTheUser = isFirstMessageOfTheUserInsideAppending(message, appended: appendMessages, isChannelType: mainData.thread?.type?.isChannelType == true)
        calculatedMessage.isFirstMessageOfTheUser = thread?.group == true && isFirstMessageOfTheUser
        calculatedMessage.isLastMessageOfTheUser = isLastMessageOfTheUserInsideAppending(message, appended: appendMessages, isChannelType: thread?.type?.isChannelType == true)
        calculatedMessage.isEnglish = message.message?.naturalTextAlignment == .leading
        calculatedMessage.markdownTitle = calculateAttributeedString(message: message)
        rowType.isPublicLink = message.isPublicLink
        rowType.isFile = message.isFileType && !rowType.isMap && !message.isImage && !message.isAudio && !message.isVideo
        rowType.isReply = message.replyInfo != nil
        if let date = message.time?.date {
            calculatedMessage.timeString = MessageRowCalculatedData.formatter.string(from: date)
        }

        rowType.isSingleEmoji = isSingleEmoji(message)
        rowType.isImage = !rowType.isMap && message.isImage
        rowType.isVideo = message.isVideo
        rowType.isAudio = message.isAudio
        rowType.isForward = message.forwardInfo != nil
        rowType.isUnSent = message.isUnsentMessage
        rowType.hasText = (!rowType.isPublicLink) && !rowType.isSingleEmoji && calculateText(message: message) != nil
        rowType.cellType = getCellType(message: message, isMe: calculatedMessage.isMe)
        calculatedMessage.callTypeKey = message.callHistory?.status?.key?.bundleLocalized() ?? ""


        calculatedMessage.computedFileSize = calculateFileSize(message: message, calculatedMessage: calculatedMessage)
        calculatedMessage.extName = calculateFileTypeWithExt(message: message, calculatedMessage: calculatedMessage)
        calculatedMessage.fileName = calculateFileName(message: message, calculatedMessage: calculatedMessage)
        calculatedMessage.addOrRemoveParticipantsAttr = calculateAddOrRemoveParticipantRow(message: message, calculatedMessage: calculatedMessage, appUserId: mainData.appUserId)
        sizes.paddings.textViewPadding = calculateTextViewPadding(message: message)
        calculatedMessage.localizedReplyFileName = calculateLocalizeReplyFileName(message: message)
        calculatedMessage.groupMessageParticipantName = calculateGroupParticipantName(message: message, calculatedMessage: calculatedMessage, thread: mainData.thread)
        sizes.replyContainerWidth = calculateReplyContainerWidth(message: message, calculatedMessage: calculatedMessage, sizes: sizes)
        sizes.forwardContainerWidth = calculateForwardContainerWidth(rowType: rowType, sizes: sizes)
        calculatedMessage.isInTwoWeekPeriod = calculateIsInTwoWeekPeriod(message: message)
//        calculatedMessage.textLayer = getTextLayer(markdownTitle: calculatedMessage.markdownTitle)
        calculatedMessage.textRect = getRect(markdownTitle: calculatedMessage.markdownTitle, width: ThreadViewModel.maxAllowedWidth - 16)

        let originalPaddings = sizes.paddings
        sizes.paddings = calculateSpacingPaddings(message: message, calculatedMessage: calculatedMessage)
        sizes.paddings.textViewPadding = originalPaddings.textViewPadding
        sizes.paddings.paddingEdgeInset = originalPaddings.paddingEdgeInset

        calculatedMessage.avatarColor = String.getMaterialColorByCharCode(str: message.participant?.name ?? message.participant?.username ?? "")
        calculatedMessage.state.isInSelectMode = mainData.isInSelectMode

        calculatedMessage.callDateText = calculateCallText(message: message)

        calculatedMessage.rowType = rowType
        let estimateHeight = calculateEstimatedHeight(calculatedMessage, sizes)
        sizes.estimatedHeight = estimateHeight
        calculatedMessage.sizes = sizes

        return calculatedMessage
    }
    
    @HistoryActor
    class func calculateColorAndFileURL(mainData: MainRequirements, message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData) async -> MessageRowCalculatedData {
        var newCal = calculatedMessage
        let color = mainData.participantsColorVM?.color(for: message.participant?.id ?? -1)
        newCal.participantColor = color ?? .clear
        newCal.fileURL = await getFileURL(serverURL: message.url)
        return newCal
    }

    class func calculatePaddings(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData) -> UIEdgeInsets {
        let isReplyOrForward = (message.forwardInfo != nil || message.replyInfo != nil) && !message.isImage
        let tailWidth: CGFloat = 6
        let paddingLeading = isReplyOrForward ? (calculatedMessage.isMe ? 10 : 16) : (calculatedMessage.isMe ? 4 : 4 + tailWidth)
        let paddingTrailing: CGFloat = isReplyOrForward ? (calculatedMessage.isMe ? 16 : 10) : (calculatedMessage.isMe ? 4 + tailWidth : 4)
        let paddingTop: CGFloat = isReplyOrForward ? 10 : 4
        let paddingBottom: CGFloat = 4
        return UIEdgeInsets(top: paddingTop, left: paddingLeading, bottom: paddingBottom, right: paddingTrailing)
    }

    class func calculateTextViewPadding(message: HistoryMessageType) -> UIEdgeInsets {
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

    class func calculateFileSize(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData) -> String? {
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

    class func calculateFileTypeWithExt(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData) -> String? {
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

    class func calculateAddOrRemoveParticipantRow(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData, appUserId: Int?) -> NSAttributedString? {
        if ![.participantJoin, .participantLeft].contains(message.type) { return nil }
        let date = Date(milliseconds: Int64(message.time ?? 0)).onlyLocaleTime
        let string = "\(message.addOrRemoveParticipantString(meId: appUserId) ?? "") \(date)"
        let attr = NSMutableAttributedString(string: string)
        let isMeDoer = "General.you".bundleLocalized()
        let doer = calculatedMessage.isMe ? isMeDoer : (message.participant?.name ?? "")
        let doerRange = NSString(string: string).range(of: doer)
        let allRange = NSRange(string.startIndex..., in: string)
        attr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: allRange)
        attr.addAttributes([
            NSAttributedString.Key.foregroundColor: UIColor(named: "accent") ?? .orange,
            NSAttributedString.Key.font: UIFont(name: "IRANSansX", size: 14) ?? .systemFont(ofSize: 14)
        ], range: doerRange)
        return attr
    }

    class func textForContianerCalculation(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData) -> String {
        let fileNameText = calculatedMessage.fileName ?? ""
        let messageText = message.message?.prefix(150).replacingOccurrences(of: "\n", with: " ") ?? ""
        let messageFileText = messageText.count > fileNameText.count ? messageText : fileNameText
        return messageFileText
    }

    class func replyPrimaryMessageFileIconWidth(calculatedMessage: MessageRowCalculatedData) -> CGFloat {
        if calculatedMessage.fileName == nil || calculatedMessage.fileName?.isEmpty == true { return 0 }
        return 32
    }

    class func calculateReplyContainerWidth(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData, sizes: MessageRowSizes) -> CGFloat? {
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

    class func calculateFileName(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData) -> String? {
        let fileName = calculatedMessage.fileMetaData?.file?.name
        if fileName == "" || fileName == "blob", let originalName = calculatedMessage.fileMetaData?.file?.originalName {
            return originalName
        }
        return fileName ?? message.uploadFileName()?.replacingOccurrences(of: ".\(message.uploadExt() ?? "")", with: "")
    }

    class func calculateForwardContainerWidth(rowType: MessageViewRowType, sizes: MessageRowSizes) -> CGFloat? {
        if rowType.isMap {
            return sizes.mapWidth - 8
        }
        return .infinity
    }

    class func calculateImageSize(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData) -> CGSize? {
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
            let hasText = message.message?.count ?? 0 > 1

            if originalWidth < designerWidth && originalHeight < designerHeight && !hasText {
                let leadingMargin: CGFloat = 4
                let trailingMargin: CGFloat = 4
                let minWidth: CGFloat = 128 // 96 to draw image downloading label and progress button over image view
                newSizes.width = max(leadingMargin + minWidth + trailingMargin, originalWidth)
                newSizes.height = originalHeight
            } else if hasText {
                newSizes.width = maxWidth
                newSizes.height = maxWidth
            } else if isSquare {
                newSizes.width = designerWidth
                newSizes.height = designerHeight
            } else {
                newSizes.width = min(designerWidth * 1.5, maxWidth)
                newSizes.height = min(designerHeight * 1.5, maxWidth)
            }

            // We do this because if we got NAN as a result of 0 / 0 we have to prepare a value other than zero
            // Because in maxWidth we can not say maxWidth is Equal zero and minWidth is equal 128
            if newSizes.width == 0 {
                newSizes.width = ThreadViewModel.maxAllowedWidth
            }
            let minWidth: CGFloat = 148 - 8 // It will prevent cutting progressView as much as possible.
            if newSizes.width < minWidth {
                newSizes.width = minWidth
            }
            return newSizes
        }
        return nil
    }

    class func calculateLocalizeReplyFileName(message: HistoryMessageType) -> String? {
        if let message = message.replyInfo?.message?.prefix(150).replacingOccurrences(of: "\n", with: " "), !message.isEmpty {
            return message
        } else if let fileHint = message.replyFileStringName?.bundleLocalized(), !fileHint.isEmpty {
            return fileHint
        } else {
            return nil
        }
    }

    class func calculateIsInTwoWeekPeriod(message: HistoryMessageType) -> Bool {
        let twoWeeksInMilliSeconds: UInt = 1_209_600_000
        let now = UInt(Date().millisecondsSince1970)
        let twoWeeksAfter = UInt(message.time ?? 0) + twoWeeksInMilliSeconds
        if twoWeeksAfter > now {
            return true
        }
        return false
    }

    class func calculateGroupParticipantName(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData, thread: Conversation?) -> String? {
        let canShowGroupName = !calculatedMessage.isMe && thread?.group == true && thread?.type?.isChannelType == false
        && calculatedMessage.isFirstMessageOfTheUser
        if canShowGroupName {
            return message.participant?.contactName ?? message.participant?.name
        }
        return nil
    }

    class func calculateReactionWidth(reactionText: String) -> CGFloat {
        let font = UIFont(name: "IRANSansX-Bold", size: 14) ?? .systemFont(ofSize: 14)
        let width = reactionText.widthOfString(usingFont: font) + 16 + 4
        return width
    }
    
    class func calulateReactions(reactions: ReactionInMemoryCopy) -> ReactionRowsCalculated {
        var rows: [ReactionRowsCalculated.Row] = []
        let summary = reactions.summary.sorted(by: {$0.count ?? 0 > $1.count ?? 0})
        summary.forEach { summary in
            let countText = summary.count?.localNumber(locale: Language.preferredLocale) ?? ""
            let emoji = summary.sticker?.emoji ?? ""
            let isMyReaction = reactions.currentUserReaction?.reaction?.rawValue == summary.sticker?.rawValue
            let hasCount = summary.count ?? -1 > 0
            let edgeInset = EdgeInsets(top: hasCount ? 6 : 0,
                                       leading: hasCount ? 8 : 0,
                                       bottom: hasCount ? 6 : 0,
                                       trailing: hasCount ? 8 : 0)
            let selectedEmojiTabId = "\(summary.sticker?.emoji ?? "all") \(countText)"
            let width = calculateReactionWidth(reactionText: selectedEmojiTabId)
            rows.append(.init(reactionId: summary.id,
                              edgeInset: edgeInset,
                              sticker: summary.sticker,
                              emoji: emoji,
                              countText: countText,
                              isMyReaction: isMyReaction,
                              hasReaction: hasCount,
                              selectedEmojiTabId: selectedEmojiTabId,
                              width: width))
        }

        // Move my reaction to the first item without sorting reactions
        let myReaction = rows.first{$0.isMyReaction}
        if let myReaction = myReaction {
            rows.removeAll(where: {$0.isMyReaction})
            rows.insert(myReaction, at: 0)
        }

        let topPadding: CGFloat = summary.count > 0 ? 10 : 0
        let myReactionSticker = reactions.currentUserReaction?.reaction
        return ReactionRowsCalculated(rows: rows, topPadding: topPadding, myReactionSticker: myReactionSticker)
    }

    class func calculateIsReplyImage(message: HistoryMessageType) -> Bool {
        if let replyInfo = message.replyInfo {
            return [ChatModels.MessageType.picture, .podSpacePicture].contains(replyInfo.messageType)
        }
        return false
    }

    class func calculateReplyLink(message: HistoryMessageType) -> String? {
        if let replyInfo = message.replyInfo {
            let metaData = replyInfo.metadata
            if let data = metaData?.data(using: .utf8), let fileMetaData = try? JSONDecoder.instance.decode(FileMetaData.self, from: data) {
                return fileMetaData.file?.link
            }
        }
        return nil
    }

    class func calculateSpacingPaddings(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData) -> MessagePaddings {
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

    class func getCellType(message: HistoryMessageType, isMe: Bool) -> CellTypes {
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

    class func calculateAttributeedString(message: HistoryMessageType) -> NSAttributedString? {
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

    class func calculateText(message: HistoryMessageType) -> String? {
        if let uploadReplyTitle = (message as? UploadFileWithReplyPrivatelyMessage)?.replyPrivatelyRequest.replyContent.text  {
            return uploadReplyTitle
        } else if let text = message.message, !text.isEmpty {
            return text
        } else {
            return nil
        }
    }

    class func isLastMessageOfTheUserInsideAppending(_ message: HistoryMessageType, appended: [HistoryMessageType], isChannelType: Bool) -> Bool {
        if isChannelType { return false }
        let index = appended.firstIndex(where: {$0.id == message.id}) ?? -2
        let nextIndex = index + 1
        let isNextExist = appended.indices.contains(nextIndex)
        if appended.count > 0, isNextExist {
            let isSameParticipant = appended[nextIndex].participant?.id == message.participant?.id
            return !isSameParticipant
        }
        return true
    }

    class func isFirstMessageOfTheUserInsideAppending(_ message: HistoryMessageType, appended: [HistoryMessageType], isChannelType: Bool) -> Bool {
        if isChannelType == true { return false }
        let index = appended.firstIndex(where: {$0.id == message.id}) ?? -2
        let prevIndex = index - 1
        let isPrevExist = appended.indices.contains(prevIndex)
        if appended.count > 0, isPrevExist {
            let isSameParticipant = appended[prevIndex].participant?.id == message.participant?.id
            return !isSameParticipant
        }
        return true
    }

    class func calculateCallText(message: HistoryMessageType) -> String? {
        if ![.endCall, .startCall].contains(message.type) { return nil }
        guard let time = message.time else { return nil }
        let date = Date(milliseconds: Int64(time))
        let text = date.onlyLocaleTime
        return text
    }

    @ChatGlobalActor
    class func getFileURL(serverURL: URL?) -> URL? {
        if let url = serverURL {
            if ChatManager.activeInstance?.file.isFileExist(url) == false { return nil }
            let fileURL = ChatManager.activeInstance?.file.filePath(url)
            return fileURL
        }
        return nil
    }

//    class func getTextLayer(markdownTitle: NSAttributedString?) -> CATextLayer? {
//        if let attributedString = markdownTitle {
//            let textLayer = CATextLayer()
//            textLayer.frame.size = getRect(markdownTitle: attributedString, width: ThreadViewModel.maxAllowedWidth)?.size ?? .zero
//            textLayer.string = attributedString
//            textLayer.backgroundColor = UIColor.clear.cgColor
//            textLayer.alignmentMode = .right
//            return textLayer
//        }
//        return nil
//    }
    
    class func isSingleEmoji(_ message: HistoryMessageType) -> Bool {
        message.message?.isEmoji == true && message.message?.isEmpty == false && message.replyInfo == nil && message.message?.count ?? 0 == 1
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
