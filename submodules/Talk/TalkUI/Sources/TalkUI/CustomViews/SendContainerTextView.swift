//
//  SendContainerTextView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/7/21.
//

import SwiftUI
import UIKit
import TalkModels

public final class SendContainerTextView: UIView, UITextViewDelegate {
    private var textView: UITextView = UITextView()
    public var mention: Bool = false
    public var onTextChanged: ((String?) -> Void)?
    private let placeholderLabel = UILabel()
    private var heightConstraint: NSLayoutConstraint!
    private let initSize: CGFloat = 42
    private let RTLMarker = "\u{200f}"

    public init() {
        super.init(frame: .zero)
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
        isUserInteractionEnabled = true
        backgroundColor = Color.App.bgSendInputUIColor
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainerInset = .init(top: 12, left: 0, bottom: 0, right: 0)
        textView.delegate = self
        textView.isEditable = true
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.returnKeyType = .default
        textView.textAlignment = Language.isRTL ? .right : .left
        addSubview(textView)

        placeholderLabel.text = "Thread.SendContainer.typeMessageHere".bundleLocalized()
        placeholderLabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.7)
        placeholderLabel.font = UIFont.uiiransansBody
        placeholderLabel.textAlignment = Language.isRTL ? .right : .left
        placeholderLabel.isUserInteractionEnabled = false
        addSubview(placeholderLabel)
        
        heightConstraint = heightAnchor.constraint(equalToConstant: initSize)

        NSLayoutConstraint.activate([
            heightConstraint,
            textView.widthAnchor.constraint(equalTo: widthAnchor, constant: 0),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.centerYAnchor.constraint(equalTo: centerYAnchor),
            textView.heightAnchor.constraint(equalTo: heightAnchor),
            
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
        let newHeight = calculateHeight()
        recalculateHeight(newHeight: newHeight)
    
        let isEmpty = isEmptyText()
        setTextDirection(isEmpty)
        
        /// Notice others the text has changed.
        onTextChanged?(textView.attributedText.string)
        
        /// Show the placeholder if the text is empty or is a rtl marker
        showPlaceholder(isEmptyText())
    }
    
    private func setTextDirection(_ isEmpty: Bool) {
        if Language.isRTL {
            if isEmpty {
                textView.attributedText = getTextAttributes(RTLMarker)
                textView.textAlignment = .right
            } else if isFirstCharacterRTL() {
                /// Replace old RTLMarker to prevent duplication
                let nonRTLText = string.replacingOccurrences(of: RTLMarker, with: "") ?? ""
                textView.attributedText = getTextAttributes("\(RTLMarker)\(nonRTLText)")
                textView.textAlignment = .right
            } else {
                /// Remove any RTLMarker if previous text had a RTLMarker.
                let nonRTLText = string.replacingOccurrences(of: RTLMarker, with: "") ?? ""
                textView.attributedText = getTextAttributes(nonRTLText)
                textView.textAlignment = .left
            }
        } else {
            textView.textAlignment = .natural
        }
    }

    private func isFirstCharacterRTL() -> Bool {
        guard let char = string.replacingOccurrences(of: RTLMarker, with: "").first else { return false }
        return char.isEnglishCharacter == false
    }

    public func isEmptyText() -> Bool {
        let isRTLChar = string.count == 1 && string.first == Character(RTLMarker)
        return string.isEmpty || isRTLChar
    }

    private func showPlaceholder(_ show: Bool) {
        if show && placeholderLabel.alpha == 0.0 {
            // From hide to show
            doPlaceHolderAnimation(1.0)
        } else if !show && placeholderLabel.alpha == 1.0 {
            // From show to hide
            doPlaceHolderAnimation(0.0)
        }
    }
    
    private func doPlaceHolderAnimation(_ toAlpha: Double) {
        UIView.animate(withDuration: 0.15) { [weak self] in
            self?.placeholderLabel.alpha = toAlpha
        } completion: { completed in
            if completed {
                self.placeholderLabel.isHidden = toAlpha == 0.0
            }
        }
    }

    private func calculateHeight() -> CGFloat {
        let fittedSize = textView.sizeThatFits(CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
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
        let attr = getTextAttributes(text)
        textView.attributedText = attr
        showPlaceholder(isEmptyText())
        textViewDidChange(textView)
    }
    
    private func getTextAttributes(_ text: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: text)
        
        /// Add default color and font for all text it will ovverde by other attributes if needed
        let allRange = NSRange(text.startIndex..., in: text)
        attr.addAttribute(.foregroundColor, value: UIColor(named: "text_primary") ?? .black, range: allRange)
        attr.addAttribute(.font, value: UIFont(name: "IRANSansX", size: 16), range: allRange)
        
        
        /// Add mention blue color and default system font due to all user names must be in english.
        text.matches(char: "@")?.forEach { match in
            attr.addAttribute(.foregroundColor, value: UIColor(named: "blue") ?? .blue, range: match.range)
            attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: match.range)
        }
        
        return attr
    }
    
    public var string: String {
        textView.attributedText.string
    }
    
}
