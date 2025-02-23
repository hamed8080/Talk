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
    private weak var viewModel: MessageRowViewModel?
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

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        setText(viewModel: viewModel)
        if let textRange = textRange(from: beginningOfDocument, to: endOfDocument) {
            setBaseWritingDirection(.rightToLeft, for: textRange)
        }
    }

    public func setText(viewModel: MessageRowViewModel) {
        self.attributedText = viewModel.calMessage.markdownTitle
        let hide = viewModel.calMessage.rowType.hasText == false && viewModel.calMessage.rowType.isPublicLink == false
        setIsHidden(hide)
    }

    // Inside a UITextView subclass:
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if forceEnableSelection { return true }
        guard let pos = closestPosition(to: point) else { return false }

        let rightLayout = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.right))
        let leftLayout = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left))
        guard let range = rightLayout ?? leftLayout else { return false }

        let startIndex = offset(from: beginningOfDocument, to: range.start)

        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}

//
//class CATextLayerView: UIView {
//    private var hConstraint: NSLayoutConstraint!
//    private var wConstrint: NSLayoutConstraint!
//    private var textLayer = CATextLayer()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        configureView()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private func configureView() {
//        translatesAutoresizingMaskIntoConstraints = false
//        hConstraint = heightAnchor.constraint(equalToConstant: 0)
//        wConstrint = widthAnchor.constraint(equalToConstant: 0)
//        NSLayoutConstraint.activate([
//            hConstraint,
//            wConstrint,
//        ])
//    }
//
//    public func set(_ viewModel: MessageRowViewModel) {
//        guard let textLayer = viewModel.calMessage.textLayer, let textRect = viewModel.calMessage.textRect else { return }
//        self.textLayer = textLayer
//        self.layer.addSublayer(self.textLayer)
//        hConstraint.constant = textRect.height
//        wConstrint.constant = textRect.width
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        textLayer.frame = bounds
//    }
//}
