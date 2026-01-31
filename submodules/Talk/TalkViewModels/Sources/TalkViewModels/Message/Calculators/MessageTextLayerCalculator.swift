//
//  MessageTextLayerCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels
import UIKit

public final class MessageTextLayerCalculator {
    private let markdownTitle: NSAttributedString?
    
    public init(markdownTitle: NSAttributedString?) {
        self.markdownTitle = markdownTitle
    }
    
    func textLayer() -> CATextLayer? {
        guard let attributedString = markdownTitle else { return nil }
        let textLayer = CATextLayer()
        textLayer.frame.size = MessageGeneralRectCalculator(markdownTitle: attributedString,
                                                            width: ThreadViewModel.maxAllowedWidth).rect()?.size ?? .zero
        textLayer.string = attributedString
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.alignmentMode = .right
        return textLayer
    }
}
