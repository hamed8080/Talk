//
//  MessageMinimumTextWidthCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels
import UIKit

public final class MessageMinimumTextWidthCalculator {
    private let textWidth: CGFloat
    
    public init(textWidth: CGFloat) {
        self.textWidth = textWidth
    }
    
    public func minimum() -> CGFloat {
        /// Padding around the text is essential, unless it will move every even small texts to the second line
        let paddingAroundText = (ConstantSizes.messageContainerStackViewPaddingAroundTextView * 2)
        let miTextWidth = min(ThreadViewModel.maxAllowedWidth - paddingAroundText, max(ConstantSizes.messageContainerStackViewMinWidth, textWidth + paddingAroundText))
        return miTextWidth
    }
}
