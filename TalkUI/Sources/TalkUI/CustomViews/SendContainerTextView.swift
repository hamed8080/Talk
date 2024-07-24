//
//  SendContainerTextView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/7/21.
//

import SwiftUI
import UIKit
import TalkModels

public final class SendContainerTextView: UITextView, UITextViewDelegate {
    public var mention: Bool = false
    public var onTextChanged: ((String?) -> Void)?
    public var onDone: ((String?) -> Void)?
    private let placeholderLabel = UILabel()
    private var heightConstraint: NSLayoutConstraint!
    private let initSize: CGFloat = 42

    public init() {
        super.init(frame: .zero, textContainer: nil)
        configureView()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        semanticContentAttribute = Locale.current.identifier.contains("fa") ? .forceRightToLeft : .forceLeftToRight
        textContainerInset = .init(top: 12, left: 0, bottom: 0, right: 0)
        delegate = self
        isEditable = true
        font = UIFont(name: "IRANSansX", size: 16)
        isSelectable = true
        isUserInteractionEnabled = true
        isScrollEnabled = true
        backgroundColor = Color.App.bgSendInputUIColor
        textColor = UIColor(named: "text_primary")
        returnKeyType = .done
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        placeholderLabel.text = "Thread.SendContainer.typeMessageHere".bundleLocalized()
        placeholderLabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.7)
        placeholderLabel.font = UIFont.fBody
        placeholderLabel.textAlignment = Language.isRTL ? .right : .left
        placeholderLabel.isUserInteractionEnabled = false
        addSubview(placeholderLabel)
        heightConstraint = heightAnchor.constraint(equalToConstant: initSize)

        NSLayoutConstraint.activate([
            heightConstraint,
            placeholderLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -8),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    func recalculateHeight(newHeight: CGFloat) {
        if frame.size.height != newHeight {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.heightConstraint.constant = newHeight // !! must be called asynchronously
                }
            }
        }
    }

    public func textViewDidChange(_ uiView: UITextView) {
        if uiView.text != text {
            let attributes = NSMutableAttributedString(string: text)
            text.matches(char: "@")?.forEach { match in
                attributes.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "blue") ?? .blue, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: match.range)
            }
            uiView.attributedText = attributes
        }
        let newHeight = calculateHeight()
        recalculateHeight(newHeight: newHeight)
        onTextChanged?(text)
        placeholderLabel.isHidden = !isEmptyText()
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn _: NSRange, replacementText text: String) -> Bool {
        if let onDone = onDone, text == "\n" {
            textView.resignFirstResponder()
            onDone(textView.text)
            return false
        }
        return true
    }

    private func isEmptyText() -> Bool {
        let isRTLChar = text.count == 1 && text.first == "\u{200f}"
        return text.isEmpty || isRTLChar
    }

    public func hidePlaceholder() {
        placeholderLabel.isHidden = true
    }

    public func showPlaceholder() {
        placeholderLabel.isHidden = false
    }

    private func calculateHeight() -> CGFloat {
        let fittedSize = sizeThatFits(CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        let minValue: CGFloat = initSize
        let maxValue: CGFloat = 192
        let newSize = min(max(fittedSize, minValue), maxValue)
        return newSize
    }

    public func updateHeightIfNeeded() {
        let newHeight = calculateHeight()
        if heightConstraint.constant != newHeight {
            recalculateHeight(newHeight: newHeight)
        }
    }
}
