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
    private let placeholderLabel = UILabel()
    private var heightConstraint: NSLayoutConstraint!
    private let initSize: CGFloat = 42
    private let RTLMarker = "\u{200f}"

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
        /// It should always remain forceLeftToRight due to textAlignment problems it can result in.
        semanticContentAttribute = .forceLeftToRight
        textContainerInset = .init(top: 12, left: 0, bottom: 0, right: 0)
        delegate = self
        isEditable = true
        font = UIFont(name: "IRANSansX", size: 16)
        isSelectable = true
        isUserInteractionEnabled = true
        isScrollEnabled = true
        backgroundColor = Color.App.bgSendInputUIColor
        textColor = UIColor(named: "text_primary")
        returnKeyType = .default
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textAlignment = Language.isRTL ? .right : .left

        placeholderLabel.text = "Thread.SendContainer.typeMessageHere".bundleLocalized()
        placeholderLabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.7)
        placeholderLabel.font = UIFont.uiiransansBody
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
        /// Change range of User mention instantly when user write @
        replaceMentionColors(uiView)
        
        let newHeight = calculateHeight()
        recalculateHeight(newHeight: newHeight)
    
        let isEmpty = isEmptyText()
        setTextDirection(isEmpty)
        
        /// Notice others the text has changed.
        onTextChanged?(text)
        
        /// Show empty textLabel if text is Empty
        placeholderLabel.isHidden = !isEmpty
    }
    
    private func setTextDirection(_ isEmpty: Bool) {
        if Language.isRTL {
            if isEmpty {
                self.text = RTLMarker
                textAlignment = .right
            } else if isFirstCharacterRTL() {
                /// Replace old RTLMarker to prevent duplication
                let nonRTLText = text.replacingOccurrences(of: RTLMarker, with: "") ?? ""
                self.text = "\(RTLMarker)\(nonRTLText)"
                textAlignment = .right
            } else {
                /// Remove any RTLMarker if previous text had a RTLMarker.
                let nonRTLText = text.replacingOccurrences(of: RTLMarker, with: "") ?? ""
                text = nonRTLText
                textAlignment = .left
            }
        } else {
            textAlignment = .natural
        }
    }
    
    private func replaceMentionColors(_ uiView: UITextView) {
        if uiView.text != text {
            let attributes = NSMutableAttributedString(string: text)
            text.matches(char: "@")?.forEach { match in
                attributes.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "blue") ?? .blue, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: match.range)
            }
            uiView.attributedText = attributes
        }
    }

    private func isFirstCharacterRTL() -> Bool {
        guard let char = text?.replacingOccurrences(of: RTLMarker, with: "").first else { return false }
        return char.isEnglishCharacter == false
    }

    private func isEmptyText() -> Bool {
        let isRTLChar = text.count == 1 && text.first == Character(RTLMarker)
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
    
    public func setTextAndDirection(_ text: String) {
        self.text = text
        textViewDidChange(self)
    }
}
