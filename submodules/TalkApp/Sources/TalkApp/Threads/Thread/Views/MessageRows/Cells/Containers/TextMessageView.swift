//
//  TextMessageView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

final class TextMessageView: UITextView {
    public var forceEnableSelection = false

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        isScrollEnabled = false
        isEditable = false
        isOpaque = true
        isSelectable = true
        isUserInteractionEnabled = true
        linkTextAttributes = [:]

        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    // Inside a UITextView subclass:
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if forceEnableSelection {
            return super.hitTest(point, with: event)
        }
        if !bounds.contains(point) { return nil }


        guard let pos = closestPosition(to: point) else { return nil }
        let rightLayout = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.right))
        let leftLayout = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left))
        guard let range = rightLayout ?? leftLayout else { return nil }

        let startIndex = offset(from: beginningOfDocument, to: range.start)
        let isLink = attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil

        return isLink ? self : nil // nil lets the touch pass through to views behind
    }
    
    public func setDirectionForRange(range: Range<String.Index>) {
        if let start = position(from: beginningOfDocument, offset: range.lowerBound.utf16Offset(in: text)),
           let end = position(from: beginningOfDocument, offset: range.upperBound.utf16Offset(in: text)) {

            setBaseWritingDirection(.leftToRight, for: textRange(from: start, to: end)!)
        }
    }
}
