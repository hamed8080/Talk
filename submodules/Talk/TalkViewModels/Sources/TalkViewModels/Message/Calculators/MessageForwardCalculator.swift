//
//  MessageForwardCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels
import UIKit

public final class MessageForwardCalculator {
    private let message: HistoryMessageType
    private let rowType: MessageViewRowType
    private let sizes: ConstantSizes
    
    public init(message: HistoryMessageType, rowType: MessageViewRowType, sizes: ConstantSizes) {
        self.message = message
        self.rowType = rowType
        self.sizes = sizes
    }
    
    public func containerWidth() -> CGFloat? {
        if rowType.isMap {
            return ConstantSizes.messageLocationWidth - 8
        }
        return .infinity
    }
}
