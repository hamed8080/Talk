//
//  MessageRowSizes.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation

public struct MessageRowSizes: Sendable {
    
    /// Paddings and margins in a message row
    nonisolated(unsafe) public static let beforeContainerLeading: CGFloat = 8
    
    /// MessageBaseCell sizes
    nonisolated(unsafe) public static let messagebaseCellWidth: CGFloat = messageAvatarBeforeLeading + messageAvatarViewSize + messageAvatarAfterTrailing
    nonisolated(unsafe) public static let messagebaseCellTrailingSpaceForShowingMoveToBottom: CGFloat = 28
    
    /// MessageContainerStackView sizes
    nonisolated(unsafe) public static let messageContainerStackViewMargin: CGFloat = 4
    nonisolated(unsafe) public static let messageContainerStackViewMinWidth: CGFloat = 58
    nonisolated(unsafe) public static let messageContainerStackViewBottomMarginForLastMeesageOfTheUser: CGFloat = 6
    nonisolated(unsafe) public static let messageContainerStackViewBottomMargin: CGFloat = 1
    nonisolated(unsafe) public static let messageContainerStackViewTopMargin: CGFloat = 1
    nonisolated(unsafe) public static let messageContainerStackViewCornerRadius: CGFloat = 10
    nonisolated(unsafe) public static let messageContainerStackViewStackSpacing: CGFloat = 4
    nonisolated(unsafe) public static let messageContainerStackViewPaddingAroundTextView: CGFloat = 8

    /// MessageAvatarView sizes
    nonisolated(unsafe) public static let messageAvatarViewSize: CGFloat = 37
    nonisolated(unsafe) public static let messageAvatarViewBottomMargin: CGFloat = 8
    nonisolated(unsafe) public static let messageAvatarBeforeLeading: CGFloat = 8
    nonisolated(unsafe) public static let messageAvatarAfterTrailing: CGFloat = 8
    
    /// MessageTailView sizes
    nonisolated(unsafe) public static let messageTailViewWidth: CGFloat = 16
    nonisolated(unsafe) public static let messageTailViewHeight: CGFloat = 32
    nonisolated(unsafe) public static let messageTailViewLeading: CGFloat = 12

    /// MessageFileView sizes
    nonisolated(unsafe) public static let messageFileViewHeight: CGFloat = 48
    nonisolated(unsafe) public static let messageFileViewStackSpacing: CGFloat = 8
    nonisolated(unsafe) public static let messageFileViewProgressButtonSize: CGFloat = 36
    nonisolated(unsafe) public static let messageFileViewStackLayoutMarginSize: CGFloat = 8
    
    /// MessageImageView sizes
    nonisolated(unsafe) public static let messageImageViewProgessSize: CGFloat = 32
    nonisolated(unsafe) public static let messageImageViewCornerRadius: CGFloat = 6
    nonisolated(unsafe) public static let messageImageViewStackSpacing: CGFloat = 6
    nonisolated(unsafe) public static let messageImageViewStackCornerRadius: CGFloat = 18
    nonisolated(unsafe) public static let messageImageViewStackLayoutMarginSize: CGFloat = 4

    /// MessageVideoView sizes
    nonisolated(unsafe) public static let messageVideoViewMargin: CGFloat = 4
    nonisolated(unsafe) public static let messageVideoViewMinWidth: CGFloat = 320
    nonisolated(unsafe) public static let messageVideoViewHeight: CGFloat = 196
    nonisolated(unsafe) public static let messageVideoViewPlayIconSize: CGFloat = 36
    nonisolated(unsafe) public static let messageVideoViewProgressButtonSize: CGFloat = 24
    nonisolated(unsafe) public static let messageVideoViewVerticalSpacing: CGFloat = 2
    
    /// MessageAudioView sizes
    nonisolated(unsafe) public static let messageAudioViewMargin: CGFloat = 6
    nonisolated(unsafe) public static let messageAudioViewVerticalSpacing: CGFloat = 4
    nonisolated(unsafe) public static let messageAudioViewProgressButtonSize: CGFloat = 42
    nonisolated(unsafe) public static let messageAudioViewPlayButtonCornerRadius: CGFloat = 12
    nonisolated(unsafe) public static let messageAudioViewFileNameWidth: CGFloat = 72
    nonisolated(unsafe) public static let messageAudioViewFileNameHeight: CGFloat = 42
    nonisolated(unsafe) public static let messageAudioViewFileWaveFormHeight: CGFloat = 42
    nonisolated(unsafe) public static let messageAudioViewPlaybackSpeedWidth: CGFloat = 52
    nonisolated(unsafe) public static let messageAudioViewPlaybackSpeedHeight: CGFloat = 28
    nonisolated(unsafe) public static let messageAudioViewPlaybackSpeedTopMargin: CGFloat = 4

    /// MessageLocationView sizes
    nonisolated(unsafe) public static let messageLocationViewMinWidth: CGFloat = 340
    nonisolated(unsafe) public static let messageLocationCornerRadius: CGFloat = 6
    
    /// We use max to at least have a width, because there are times that maxWidth is nil.
    nonisolated(unsafe) public static let messageLocationWidth: CGFloat = max(128, (ThreadViewModel.maxAllowedWidth)) - (18 + messageTailViewWidth)
    /// We use max to at least have a width, because there are times that maxWidth is nil.
    /// We use min to prevent the image gets bigger than 320 if it's bigger.
    nonisolated(unsafe) public static let messageLocationHeight: CGFloat = min(320, max(128, (ThreadViewModel.maxAllowedWidth)))

    /// GroupParticipantNameView sizes
    nonisolated(unsafe) public static let groupParticipantNameViewHeight: CGFloat = 16
    
    /// MessageReplyInfoView sizes
    nonisolated(unsafe) public static let messageReplyInfoViewHeight: CGFloat = 54
    nonisolated(unsafe) public static let messageReplyInfoViewMargin: CGFloat = 6
    nonisolated(unsafe) public static let messageReplyInfoViewImageSize: CGFloat = 36
    nonisolated(unsafe) public static let messageReplyInfoViewBarWidth: CGFloat = 2.5
    nonisolated(unsafe) public static let messageReplyInfoViewBarMargin: CGFloat = 0.5
    nonisolated(unsafe) public static let messageReplyInfoViewCornerRadius: CGFloat = 8
    nonisolated(unsafe) public static let messageReplyInfoViewImageIconCornerRadius: CGFloat = 4
    nonisolated(unsafe) public static let messageReplyInfoViewBarCornerRadius: CGFloat = 2
    nonisolated(unsafe) public static let messageReplyInfoViewLableHeight: CGFloat = 18

    /// MessageForwardInfoView sizes
    nonisolated(unsafe) public static let messageForwardInfoViewHeight: CGFloat = 48
    nonisolated(unsafe) public static let messageForwardInfoViewMargin: CGFloat = 6
    nonisolated(unsafe) public static let messageForwardInfoViewImageSize: CGFloat = 36
    nonisolated(unsafe) public static let messageForwardInfoViewBarWidth: CGFloat = 2.5
    nonisolated(unsafe) public static let messageForwardInfoViewBarMargin: CGFloat = 0.5
    nonisolated(unsafe) public static let messageForwardInfoViewVerticalSpacing: CGFloat = 2.0
    nonisolated(unsafe) public static let messageForwardInfoViewStackCornerRadius: CGFloat = 6

    /// MessageSingleEmojiView sizes
    nonisolated(unsafe) public static let messageSingleEmojiViewFontSize: CGFloat = 64
    nonisolated(unsafe) public static let messageSingleEmojiViewHeight: CGFloat = 64
    
    /// MessageFooterView sizes
    nonisolated(unsafe) public static let messageFooterViewHeightWithReaction: CGFloat = 28
    nonisolated(unsafe) public static let messageFooterViewHeightWithoutReaction: CGFloat = 16
    nonisolated(unsafe) public static let messageFooterViewNormalStatusWidth: CGFloat = 12
    nonisolated(unsafe) public static let messageFooterViewSeenWidth: CGFloat = 22
    nonisolated(unsafe) public static let messageFooterViewPinWidth: CGFloat = 22
    nonisolated(unsafe) public static let messageFooterViewStatusHeight: CGFloat = 16
    nonisolated(unsafe) public static let messageFooterViewStackSpacing: CGFloat = 4

    /// SelectMessageRadio sizes
    nonisolated(unsafe) public static let selectMessageRadioWidth: CGFloat = 48
    nonisolated(unsafe) public static let selectMessageRadioHeight: CGFloat = 48
    nonisolated(unsafe) public static let selectMessageRadioImageViewWidth: CGFloat = 28
    nonisolated(unsafe) public static let selectMessageRadioImageViewHeight: CGFloat = 28
    nonisolated(unsafe) public static let selectMessageRadioBottomConstant: CGFloat = 10
    nonisolated(unsafe) public static let selectMessageRadioNegativeConstantOnSelection: CGFloat = -8

    /// SelectMessageRadio sizes
    nonisolated(unsafe) public static let unsentMessageViewHeight: CGFloat = 28
    nonisolated(unsafe) public static let unsentMessageViewBtnResendLeading: CGFloat = 8
    
    /// FooterReactionsCountView(Container of the reaction and time/pin/status...) sizes
    nonisolated(unsafe) public static let footerReactionsCountViewMaxReactionsToShow: Int = 4
    nonisolated(unsafe) public static let footerReactionsCountViewStackSpacing: CGFloat = 4
    nonisolated(unsafe) public static let footerReactionsCountViewScrollViewHeight: CGFloat = 28
    nonisolated(unsafe) public static let footerReactionsCountViewScrollViewMaxWidth: CGFloat = 200
    
    /// MessageReactionRowView sizes
    nonisolated(unsafe) public static let messageReactionRowViewTotalWidth: CGFloat = 42
    nonisolated(unsafe) public static let messageReactionRowViewEmojiWidth: CGFloat = 20
    nonisolated(unsafe) public static let messageReactionRowViewMargin: CGFloat = 8
    nonisolated(unsafe) public static let messageReactionRowViewCornerRadius: CGFloat = 14
    nonisolated(unsafe) public static let messageReactionRowViewHeight: CGFloat = 28
    nonisolated(unsafe) public static let messageReactionRowViewTopMargin : CGFloat = 6
    
    /// MessageUnreadBubbleCell sizes
    nonisolated(unsafe) public static let messageUnreadBubbleCellHeight: CGFloat = 48
    nonisolated(unsafe) public static let messageUnreadBubbleCellLableHeight: CGFloat = 30
    
    /// SectionHeaderView sizes
    nonisolated(unsafe) public static let sectionHeaderViewHeight: CGFloat = 28
    nonisolated(unsafe) public static let sectionHeaderViewLabelCornerRadius: CGFloat = 14
    nonisolated(unsafe) public static let sectionHeaderViewLableHorizontalPadding: CGFloat = 32
    nonisolated(unsafe) public static let sectionHeaderViewLableVerticalPadding: CGFloat = 8
    
    /// ParticipantsEventCell sizes
    nonisolated(unsafe) public static let messageParticipantsEventCellCornerRadius: CGFloat = 14
    nonisolated(unsafe) public static let messageParticipantsEventCellMargin: CGFloat = 4
    nonisolated(unsafe) public static let messageParticipantsEventCellWidthRedaction: CGFloat = 24
    nonisolated(unsafe) public static let messageParticipantsEventCellLableHorizontalPadding: CGFloat = 16
    nonisolated(unsafe) public static let messageParticipantsEventCellLableVerticalPadding: CGFloat = 8
    
    /// CallEventCell sizes
    nonisolated(unsafe) public static let messageCallEventCellStackSapcing: CGFloat = 12
    nonisolated(unsafe) public static let messageCallEventCellStackCornerRadius: CGFloat = 14
    nonisolated(unsafe) public static let messageCallEventCellStackLayoutMargin: CGFloat = 16
    nonisolated(unsafe) public static let messageCallEventCellHeight: CGFloat = 32
    nonisolated(unsafe) public static let messageCallEventCellStackMargin: CGFloat = 4
    
    /// Buttons vertical stack for mention/jump to bottom
    nonisolated(unsafe) public static let vStackButtonsLeadingMargin: CGFloat = 8

    public var paddings = MessagePaddings()
    public var estimatedHeight: CGFloat = 0
    public var replyContainerWidth: CGFloat?
    public var forwardContainerWidth: CGFloat?
    public var imageWidth: CGFloat? = nil
    public var imageHeight: CGFloat? = nil
    public var minTextWidth: CGFloat? = nil

    public init(){}
}
