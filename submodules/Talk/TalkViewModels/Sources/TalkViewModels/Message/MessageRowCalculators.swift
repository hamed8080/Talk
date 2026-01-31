//
//  MessageRowCalculators.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import TalkModels
import Chat
import TalkExtensions
import TalkFont

struct CalculatedDataResult {
    var calData: MessageRowCalculatedData
    var message: HistoryMessageType
}

public final actor MessageRowCalculators {
    private let mainData: MainRequirements
    private let messages: [HistoryMessageType]
    private let threadViewModel: ThreadViewModel
    
    public init(messages: [HistoryMessageType], mainData: MainRequirements, threadViewModel: ThreadViewModel) {
        self.messages = messages
        self.mainData = mainData        
        self.threadViewModel = threadViewModel
    }
    
    func batchCalulate() async -> [MessageRowViewModel] {
        let dataResults = await calculateWithGroup()
        return await createViewModels(dataResults)
    }
    
    private func calculateWithGroup() async -> [CalculatedDataResult] {
        let msgsCal = await withTaskGroup(of: CalculatedDataResult.self) { group in
            for message in messages {
                group.addTask {
                    let calculatedData = await self.calculate(message: message)
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
   
    @MainActor
    private func createViewModels(_ results: [CalculatedDataResult]) -> [MessageRowViewModel] {
        var viewModels: [MessageRowViewModel] = []
        for result in results {
            let vm = MessageRowViewModel(message: result.message, viewModel: threadViewModel)
            vm.calMessage = result.calData
            if vm.calMessage.fileURL != nil {
                let fileState = completionFileState(vm.fileState, result.message.iconName)
                vm.setFileState(fileState, fileURL: nil)
            }
            viewModels.append(vm)
        }
        return viewModels
    }

    @MainActor
    private func completionFileState(_ oldState: MessageFileState, _ iconName: String?) -> MessageFileState {
        var fileState = oldState
        fileState.state = .completed
        fileState.showDownload = false
        fileState.iconState = iconName ?? ""
        return fileState
    }
    
    func calculate(message: HistoryMessageType) async -> MessageRowCalculatedData {
        var calculatedMessage = MessageRowCalculatedData()
        var sizes = ConstantSizes()
        let thread = mainData.thread
        let isChannelType = thread?.type?.isChannelType == true
        
        let isMine = message.isMe(currentUserId: mainData.appUserId) || message is UploadProtocol
        let fileMetaData = message.fileMetaData /// decoding data so expensive if it will happen on the main thread.
        
        let rowType = MessageRowTypeCalculator(
            message: message,
            isMine: isMine,
            fileMetaData: fileMetaData,
            joinLink: mainData.joinLink
        ).rowType()
        
        calculatedMessage.isMe = isMine
        calculatedMessage.canShowIconFile = message.replyInfo?.messageType != .text && message.replyInfo?.deleted == false
        calculatedMessage.fileMetaData = fileMetaData
        let imageResult = MessageImageSizeCalculator(message: message, fileMetaData: calculatedMessage.fileMetaData, isImage: rowType.isImage).imageSize()
        sizes.imageWidth = imageResult?.width
        sizes.imageHeight = imageResult?.height
        
        let replyCal = MessageReplyInfoCalculator(message: message, sizes: sizes, calculatedMessage: calculatedMessage, isImage: rowType.isImage)
        calculatedMessage.isReplyImage = replyCal.calculateIsReplyImage()
        calculatedMessage.replyLink = replyCal.replyLink()        
        sizes.paddings.paddingEdgeInset = MessageEdgeInsetPaddingCalculator(message: message, calculatedMessage: calculatedMessage, isImage: rowType.isImage).edgeInset()
        calculatedMessage.avatarSplitedCharaters = String.splitedCharacter(message.participant?.name ?? message.participant?.username ?? "")
        
        calculatedMessage.canEdit = MessageCanEditCalculator(message: message, conversation: thread, isMine: isMine).canEdit()
        
        let firstOrLastCal = MessageFirstOrLastCalculator(message: message, appended: messages, isChannelType: isChannelType)
        calculatedMessage.isFirstMessageOfTheUser = firstOrLastCal.isFirst()
        calculatedMessage.isLastMessageOfTheUser = firstOrLastCal.isLast()
        
        let mapUploadText = (message as? UploadFileMessage)?.locationRequest?.textMessage
        if let attributedString = MessageAttributedStringCalculator(message: message).attributedString() {
            calculatedMessage.attributedString = attributedString
        }
        calculatedMessage.rangeCodebackground = MessageTripleGraveAccentCalculator(message: message, pattern: "(?s)```\n(.*?)\n```").calculateRange(text: calculatedMessage.attributedString?.string ?? "")
        if let date = message.time?.date {
            calculatedMessage.timeString = MessageRowCalculators.hourFormatter.string(from: date)
        }
        
        /// File Size/ Name/ Extension
        calculatedMessage.computedFileSize = MessageFileSizeCalculator(message: message, fileMetaData: calculatedMessage.fileMetaData).calculate()
        calculatedMessage.extName = MessageFileTypeExtensionCalculator(message: message, fileMetaData: calculatedMessage.fileMetaData).fileTypeString()
        calculatedMessage.fileName = MessageFileNameCalculator(message: message, fileMetaData: calculatedMessage.fileMetaData).calculateFileName()
        
        calculatedMessage.addOrRemoveParticipantsAttr = MessageAddOrRemoveParticipantCalculator(message: message, isMine: calculatedMessage.isMe, myId: mainData.appUserId).attribute()
        sizes.paddings.textViewPadding = MessagePaddingCalculator(message: message, calculatedMessage: calculatedMessage).textViewEdgeInset()
        
        let replyInfoCal = MessageReplyInfoCalculator(message: message, sizes: sizes, calculatedMessage: calculatedMessage, isImage: rowType.isImage)
        calculatedMessage.replyFileName = replyInfoCal.replyFileName()
        calculatedMessage.groupMessageParticipantName = MessageGroupParticipantNameCalculator(
            message: message,
            isMine: calculatedMessage.isMe,
            isFirstMessageOfTheUser: calculatedMessage.isFirstMessageOfTheUser,
            conversation: thread)
        .participantName()
        sizes.replyContainerWidth = replyInfoCal.calculateContainerWidth()
        sizes.forwardContainerWidth = MessageForwardCalculator(message: message, rowType: rowType, sizes: sizes).containerWidth()
        // calculatedMessage.textLayer = MessageTextLayerCalculator(markdownTitle: attributedString).textLayer()
        
        if (sizes.forwardContainerWidth == .infinity || sizes.forwardContainerWidth == nil) && message.forwardInfo != nil && rowType.isImage {
            sizes.imageWidth = ThreadViewModel.maxAllowedWidth
        }
        
        if sizes.replyContainerWidth == nil && message.replyInfo != nil && rowType.isImage {
            sizes.imageWidth = ThreadViewModel.maxAllowedWidth
        }
        
        if let attr = calculatedMessage.addOrRemoveParticipantsAttr {
            calculatedMessage.textRect = MessageGeneralRectCalculator(markdownTitle: attr, width: ThreadViewModel.maxAllowedWidth).rect()
        } else if let attr = calculatedMessage.attributedString {
            let width = calculatedMessage.isMe ? ThreadViewModel.maxAllowedWidthIsMe : ThreadViewModel.maxAllowedWidth
            calculatedMessage.textRect = MessageGeneralRectCalculator(markdownTitle: attr, width: width).rect()
        }
        
        /// View Size/EdgeInset and Paddings
        let originalPaddings = sizes.paddings
        let paddingCal = MessagePaddingCalculator(message: message, calculatedMessage: calculatedMessage)
        sizes.paddings = paddingCal.paddings()
        sizes.paddings.textViewPadding = originalPaddings.textViewPadding
        sizes.paddings.paddingEdgeInset = originalPaddings.paddingEdgeInset
        
        calculatedMessage.avatarColor = String.getMaterialColorByCharCode(str: message.participant?.name ?? message.participant?.username ?? "")
        calculatedMessage.state.isInSelectMode = mainData.isInSelectMode
        
        calculatedMessage.callAttributedString = MessagCallTextCalculator(message: message, myId: mainData.appUserId).attribute()
        sizes.minTextWidth = MessageMinimumTextWidthCalculator(textWidth: calculatedMessage.textRect?.width ?? 0).minimum()
        
        calculatedMessage.rowType = rowType
        let estimateHeight = MessageHeightEstimationCalculator(
            message: message,
            sizes: sizes,
            rowType: rowType,
            isFirstMessageOfTheUser: calculatedMessage.isFirstMessageOfTheUser,
            isMine: calculatedMessage.isMe,
            addOrRemoveParticipantsAttr: calculatedMessage.addOrRemoveParticipantsAttr,
            textRect: calculatedMessage.textRect
        ).estimate()
        sizes.estimatedHeight = estimateHeight
        calculatedMessage.sizes = sizes
        
        /// Color of participant
        calculatedMessage.participantColor = await MessageParticipantColorCalculator(
            message: message,
            participantsColorVM: mainData.participantsColorVM)
        .color()
        
        /// Normal file file url
        let fileURL = await MessageFilePathOnDiskCalculator(message: message).getFileURL()
        calculatedMessage.fileURL = fileURL
        
        /// Audio file url
        if let fileURL = fileURL, let url = MessagePlayerItemCalculator.audioURL(fileURL: fileURL, message: message, isAudio: rowType.isAudio) {
            calculatedMessage.fileURL = url
            let audioCal = MessagePlayerItemCalculator(message: message, url: url, metadata: calculatedMessage.fileMetaData)
            calculatedMessage.avPlayerItem = await audioCal.playerItem()
        }
        
        return calculatedMessage
    }
}

extension MessageRowCalculators {
    nonisolated(unsafe) public static var hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Language.preferredLocale
        return formatter
    }()
}
