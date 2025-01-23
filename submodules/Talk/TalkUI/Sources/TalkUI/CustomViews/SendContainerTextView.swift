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
        textView.backgroundColor = Color.App.bgSendInputUIColor
        addSubview(textView)
        
        placeholderLabel.text = "Thread.SendContainer.typeMessageHere".bundleLocalized()
        placeholderLabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.7)
        placeholderLabel.font = UIFont.uiiransansSubheadline
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
    
    public func setTextAndDirection(_ text: String) {
        textView.attributedText = getTextAttributes(text)
        showPlaceholder(isEmptyText())
        textViewDidChange(textView)
    }
    
    public func textViewDidChange(_ uiView: UITextView) {
        let newHeight = calculateHeight()
        recalculateHeight(newHeight: newHeight)
        
        updateTextDirection()
        
        /// Notice others the text has changed.
        onTextChanged?(textView.attributedText.string)
        
        /// Show the placeholder if the text is empty or is a rtl marker
        showPlaceholder(isEmptyText())
    }
    
    private func updateTextDirection() {
        guard let firstCharacter = string.first else {
            setAlignment(.right)
            return
        }
        
        if firstCharacter == Character(RTLMarker) || isFirstCharacterRTL() {
            setAlignment(.right)
        } else {
            setAlignment(.left)
        }
    }
    
    private func setAlignment(_ alignment: NSTextAlignment) {
        if textView.textAlignment != alignment {
            textView.textAlignment = alignment
        }
    }
    
    private func isFirstCharacterRTL() -> Bool {
        guard let char = string.replacingOccurrences(of: RTLMarker, with: "").first else { return false }
        return char.isEnglishCharacter == false
    }
    
    public func isEmptyText() -> Bool {
        let isRTLChar = string.count == 1 && string.first == Character(RTLMarker)
        return string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRTLChar
    }
    
    private func showPlaceholder(_ show: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.placeholderLabel.alpha = show ? 1.0 : 0.0
        } completion: { completed in
            if completed {
                self.placeholderLabel.isHidden = !show
            }
        }
    }
    
    private func calculateHeight() -> CGFloat {
        let fittedSize = textView.sizeThatFits(CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        return min(max(fittedSize, initSize), 192)
    }
    
    public func updateHeightIfNeeded() {
        let newHeight = calculateHeight()
        if heightConstraint.constant != newHeight {
            recalculateHeight(newHeight: newHeight)
        }
    }
    
    func recalculateHeight(newHeight: CGFloat) {
        if frame.size.height != newHeight {
            UIView.animate(withDuration: 0.3) {
                self.heightConstraint.constant = newHeight // !! must be called asynchronously
            }
        }
    }
    
    private func getTextAttributes(_ text: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: text)
        
        /// Add default color and font for all text it will ovverde by other attributes if needed
        let allRange = NSRange(text.startIndex..., in: text)
        attr.addAttribute(.foregroundColor, value: UIColor(named: "text_primary") ?? .black, range: allRange)
        attr.addAttribute(.font, value: UIFont(name: "IRANSansX", size: 16), range: allRange)
        
        
        /// Add mention blue color and default system font due to all user names must be in english.
        text.matches(char: "@")?.forEach { match in
            attr.addAttribute(.foregroundColor, value: UIColor(named: "accent") ?? .blue, range: match.range)
            attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .bold), range: match.range)
        }
        
        return attr
    }
    
    public var string: String {
        textView.attributedText.string
    }
    
    public func focus() {
        textView.becomeFirstResponder()
    }
    
    public func unfocus() {
        textView.resignFirstResponder()
    }
}
