//
//  MessagePaddings.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import UIKit
import SwiftUI

public struct MessagePaddings: Sendable {
    public var textViewPadding: UIEdgeInsets
    public var textViewSpacingTop: CGFloat = 0
    public var replyViewSpacingTop: CGFloat = 0
    public var forwardViewSpacingTop: CGFloat = 0
    public var fileViewSpacingTop: CGFloat = 0
    public var paddingEdgeInset: UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
    public var radioPadding: UIEdgeInsets = .init(top: 0, left: 0, bottom: 8, right: 0)
    public var mapViewSapcingTop: CGFloat = 0
    public var groupParticipantNamePadding: UIEdgeInsets = .init(top: 0, left: 0, bottom: 8, right: 0)

    public init(
        textViewPadding: UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
    ) {
        self.textViewPadding = textViewPadding
    }
}
