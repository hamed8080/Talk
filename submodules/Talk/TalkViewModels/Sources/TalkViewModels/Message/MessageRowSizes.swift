//
//  MessageRowSizes.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation

public struct MessageRowSizes: Sendable {
    nonisolated(unsafe) public static var avatarSize: CGFloat = 37
    public static let tailSize: CGSize = .init(width: 6, height: 12)
    public var paddings = MessagePaddings()
    public var estimatedHeight: CGFloat = 0
    public var replyContainerWidth: CGFloat?
    public var forwardContainerWidth: CGFloat?
    public var imageWidth: CGFloat? = nil
    public var imageHeight: CGFloat? = nil

    /// We use max to at least have a width, because there are times that maxWidth is nil.
    public let mapWidth = max(128, (ThreadViewModel.maxAllowedWidth)) - (18 + tailSize.width)
    /// We use max to at least have a width, because there are times that maxWidth is nil.
    /// We use min to prevent the image gets bigger than 320 if it's bigger.
    public let mapHeight = min(320, max(128, (ThreadViewModel.maxAllowedWidth)))

    public init(){}
}
