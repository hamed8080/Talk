//
//  MessageHeightEstimationCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels

public final class MessageHeightEstimationCalculator {
    private let message: HistoryMessageType
    private let sizes: ConstantSizes
    private let isReactionable: Bool
    private let rowType: MessageViewRowType
    private let isFirstMessageOfTheUser: Bool
    private let isMine: Bool
    private let addOrRemoveParticipantsAttr: NSAttributedString?
    private let textRect: CGRect?
    
    public init(
        message: HistoryMessageType, sizes: ConstantSizes,
        rowType: MessageViewRowType, isFirstMessageOfTheUser: Bool, isMine: Bool,
        addOrRemoveParticipantsAttr: NSAttributedString?,
        textRect: CGRect?
    ) {
        self.message = message
        self.sizes = sizes
        self.isReactionable = message.reactionableType
        self.rowType = rowType
        self.isFirstMessageOfTheUser = isFirstMessageOfTheUser
        self.isMine = isMine
        self.addOrRemoveParticipantsAttr = addOrRemoveParticipantsAttr
        self.textRect = textRect
    }

    func estimate() -> CGFloat {
        if rowType.cellType == .call {
            return ConstantSizes.messageCallEventCellHeight
        } else if rowType.cellType == .participants, let attr = addOrRemoveParticipantsAttr {
            let horizontalPadding: CGFloat = ConstantSizes.messageParticipantsEventCellLableHorizontalPadding * 2
            let drawableWidth = ThreadViewModel.threadWidth - (ConstantSizes.messageParticipantsEventCellWidthRedaction + horizontalPadding)
            let height = MessageGeneralRectCalculator(markdownTitle: attr, width: drawableWidth).rect()?.height ?? 0
            return height + (ConstantSizes .messageParticipantsEventCellLableVerticalPadding) + (ConstantSizes.messageParticipantsEventCellMargin * 2)
        } else if rowType.isSingleEmoji {
            return ConstantSizes.messageSingleEmojiViewHeight
        } else if rowType.cellType == .unreadBanner {
            return ConstantSizes.messageUnreadBubbleCellHeight
        }

        let containerMargin: CGFloat = isFirstMessageOfTheUser ? ConstantSizes .messageContainerStackViewBottomMarginForLastMeesageOfTheUser : ConstantSizes.messageContainerStackViewBottomMargin

        var estimatedHeight: CGFloat = 0

        /// Stack layout marging for both top and bottom
        let margin: CGFloat = ConstantSizes.messageContainerStackViewMargin * 2

        estimatedHeight += ConstantSizes.messageContainerStackViewStackSpacing

        estimatedHeight += containerMargin
        estimatedHeight += margin

        /// Group participant name height
        if isFirstMessageOfTheUser && !isMine {
            estimatedHeight += ConstantSizes.groupParticipantNameViewHeight
            estimatedHeight +=
                ConstantSizes.messageContainerStackViewStackSpacing
        }

        if rowType.isReply {
            estimatedHeight += ConstantSizes.messageReplyInfoViewHeight
            estimatedHeight +=
                ConstantSizes.messageContainerStackViewStackSpacing
        }

        if rowType.isForward {
            estimatedHeight += ConstantSizes.messageForwardInfoViewHeight
            estimatedHeight +=
                ConstantSizes.messageContainerStackViewStackSpacing
        }

        if rowType.isImage {
            estimatedHeight += sizes.imageHeight ?? 0
            estimatedHeight +=
                ConstantSizes.messageContainerStackViewStackSpacing
        }

        if rowType.isVideo {
            estimatedHeight += ConstantSizes.messageVideoViewHeight
            estimatedHeight +=
                ConstantSizes.messageContainerStackViewStackSpacing
        }

        if rowType.isAudio {
            estimatedHeight += ConstantSizes.messageAudioViewFileNameHeight
            estimatedHeight += ConstantSizes.messageAudioViewMargin

            estimatedHeight += ConstantSizes.messageAudioViewMargin
            estimatedHeight += ConstantSizes.messageAudioViewFileWaveFormHeight

            estimatedHeight += ConstantSizes.messageAudioViewPlaybackSpeedHeight
            estimatedHeight +=
                ConstantSizes.messageContainerStackViewStackSpacing
        }

        if rowType.isFile {
            estimatedHeight += ConstantSizes.messageFileViewHeight
            estimatedHeight +=
                ConstantSizes.messageContainerStackViewStackSpacing
        }

        if rowType.isMap {
            estimatedHeight += ConstantSizes.messageLocationHeight  // static inside MessageRowCalculatedData
            estimatedHeight +=
                ConstantSizes.messageContainerStackViewStackSpacing
        }

        if rowType.hasText {
            estimatedHeight += textRect?.height ?? 0
            estimatedHeight +=
                ConstantSizes.messageContainerStackViewStackSpacing
        }

        /// Footer height
        /// Reactions are not part of the estimation.
        if isReactionable {
            estimatedHeight += ConstantSizes.messageFooterViewHeight
            estimatedHeight += margin
            estimatedHeight += containerMargin
            estimatedHeight +=
                (message.id ?? 0) == 0
                ? 0 : ConstantSizes.messageContainerStackViewStackSpacing
        }

        return estimatedHeight
    }
}
