//
//  MessageRowState.swift
//  TalkViewModels
//
//  Created by hamed on 3/9/23.
//

import Foundation

public struct MessageRowState: Sendable {
    public var isSelected: Bool = false
    public var isInSelectMode: Bool = false
    public var isHighlited: Bool = false
    public var showReactionsOverlay = false
    public var isPreparingThumbnailImageForUploadedImage = false

    public init() {}
}
