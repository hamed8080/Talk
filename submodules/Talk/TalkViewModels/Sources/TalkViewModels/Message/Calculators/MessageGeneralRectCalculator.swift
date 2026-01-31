//
//  MessageGeneralRectCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import UIKit

public final class MessageGeneralRectCalculator {
    private let markdownTitle: NSAttributedString
    private let width: CGFloat
    
    public init(markdownTitle: NSAttributedString, width: CGFloat) {
        self.markdownTitle = markdownTitle
        self.width = width
    }
    
    func rect() -> CGRect? {
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
}
