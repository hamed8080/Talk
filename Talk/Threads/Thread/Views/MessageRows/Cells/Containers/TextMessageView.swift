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

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        isScrollEnabled = false
        isEditable = false
        isSelectable = false /// Only is going to be enable when we are in context menu
        ///
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapJoinGroup(_:)))
        addGestureRecognizer(tap)
    }

    public func set(_ viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.hasText {
            reset()
        }
        self.viewModel = viewModel
        textAlignment = viewModel.calMessage.isMe || !viewModel.calMessage.isEnglish ? .right : .left
        backgroundColor = .clear
        isUserInteractionEnabled = viewModel.calMessage.rowType.isPublicLink
        setText()
    }

    @objc func onTapJoinGroup(_ sender: UIGestureRecognizer) {
        print("tap on group link")
    }

    private func reset() {
        setIsHidden(true)
    }

    public func setText() {
        self.attributedText = self.viewModel?.calMessage.markdownTitle
        self.textColor = Color.App.textPrimaryUIColor
        self.font = UIFont.uiiransansBody
        setIsHidden(viewModel?.calMessage.rowType.hasText == false)
    }
}

class CATextLayerView: UIView {
    private var hConstraint: NSLayoutConstraint!
    private var wConstrint: NSLayoutConstraint!
    private var textLayer = CATextLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        hConstraint = heightAnchor.constraint(equalToConstant: 0)
        wConstrint = widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            hConstraint,
            wConstrint,
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        guard let textLayer = viewModel.calMessage.textLayer, let textRect = viewModel.calMessage.textRect else { return }
        self.textLayer = textLayer
        self.layer.addSublayer(self.textLayer)
        hConstraint.constant = textRect.height
        wConstrint.constant = textRect.width
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textLayer.frame = bounds
    }
}