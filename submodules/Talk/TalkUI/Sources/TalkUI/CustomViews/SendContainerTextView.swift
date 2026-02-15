//
//  SendContainerTextView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/7/21.
//

import SwiftUI
import UIKit
import TalkModels
import TalkViewModels

public final class SendContainerTextView: UIView, UITextViewDelegate {
    private var textView: UITextView = UITextView()
    private var btnEmoji = UIImageButton(imagePadding: .init(all: 0))
    public var onTextChanged: ((String?) -> Void)?
    public var onHeightChange: ((CGFloat) -> Void)?
    private let placeholderLabel = UILabel()
    private var heightConstraint: NSLayoutConstraint!
    private let initSize: CGFloat = 52
    private let initSizeEmoji: CGFloat = 32
    private let RTLMarker = "\u{200f}"
    public weak var threadVM: ThreadViewModel?
    public var viewModel: SendContainerViewModel? { threadVM?.sendContainerViewModel }
    
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
        /// It should always remain forceLeftToRight to avoid text alignment problems.
        semanticContentAttribute = .forceLeftToRight
        isUserInteractionEnabled = true
        backgroundColor = Color.App.bgSendInputUIColor
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainerInset = .init(top: 16, left: 2, bottom: 14, right: 10)
        textView.delegate = self
        textView.isEditable = true
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.returnKeyType = .default
        textView.textAlignment = Language.isRTL ? .right : .left
        textView.backgroundColor = Color.App.bgSendInputUIColor
    
        btnEmoji.translatesAutoresizingMaskIntoConstraints = false
        btnEmoji.imageView.image = UIImage(named: "emoji")
        btnEmoji.tintColor = Color.App.textSecondaryUIColor
        btnEmoji.action = { [weak self] in
            self?.onEmojiTapped()
        }
        addSubview(btnEmoji)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = Language.isRTL ? .right : .left
        
        textView.typingAttributes = [
            .font: UIFont.normal(.subheadline),
            .foregroundColor: UIColor(named: "text_primary") ?? .black,
            .paragraphStyle: paragraphStyle
        ]
        addSubview(textView)
        
        placeholderLabel.text = "Thread.SendContainer.typeMessageHere".bundleLocalized()
        placeholderLabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.7)
        placeholderLabel.font = UIFont.normal(.subheadline)
        placeholderLabel.textAlignment = Language.isRTL ? .right : .left
        placeholderLabel.isUserInteractionEnabled = false
        addSubview(placeholderLabel)
        
        heightConstraint = heightAnchor.constraint(equalToConstant: initSize)
        
        NSLayoutConstraint.activate([
            heightConstraint,
            
            btnEmoji.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            btnEmoji.widthAnchor.constraint(equalToConstant: initSizeEmoji),
            btnEmoji.heightAnchor.constraint(equalToConstant: initSizeEmoji),
            btnEmoji.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6.5),
            
            textView.leadingAnchor.constraint(equalTo: btnEmoji.trailingAnchor, constant: 2),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.centerYAnchor.constraint(equalTo: centerYAnchor),
            textView.heightAnchor.constraint(equalTo: heightAnchor),
                        
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: Language.isRTL ? -16 : 16),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -16),
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2.5),
            placeholderLabel.heightAnchor.constraint(equalTo: heightAnchor),
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
        
        // Detect mentions and update attributes
        updateMentionAttributes()
        
        updateTextDirection()
        
        /// Notice others the text has changed.
        onTextChanged?(textView.attributedText.string)
        
        /// Show the placeholder if the text is empty or is a rtl marker
        showPlaceholder(isEmptyText())
    }
    
    private func updateTextDirection() {
        guard let firstCharacter = string.first, !isEmptyText() else {
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
        let fittedSize = textView.sizeThatFits(CGSize(width: frame.size.width - initSizeEmoji, height: CGFloat.greatestFiniteMagnitude)).height
        /// initSize + 16 to check if we are in the new line or not to prevent a change in the height
        if fittedSize < initSize + 16 { return initSize }
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
                self.heightConstraint.constant = newHeight // !! must be called asynchronouslyUIStackView
                self.onHeightChange?(newHeight)
            }
        }
    }
    
    private func updateMentionAttributes() {
        // Preserve the current alignment and cursor position
        let cursorPosition = textView.selectedRange
        let currentAlignment = textView.textAlignment
        
        // Update the text view's attributed text
        textView.attributedText = getTextAttributes(string)

        // Reapply the preserved alignment and cursor position
        textView.textAlignment = currentAlignment
        textView.selectedRange = cursorPosition
    }
    
    private func getTextAttributes(_ text: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: text)
        
        /// Add default color and font for all text it will ovverde by other attributes if needed
        let allRange = NSRange(text.startIndex..., in: text)
        attr.addAttribute(.foregroundColor, value: UIColor(named: "text_primary") ?? .black, range: allRange)
        attr.addAttribute(.font, value: UIFont.normal(.subheadline), range: allRange)
        
        /// Add mention accent color and default system font due to all user names must be in english.
        let mentionPattern = "@[A-Za-z0-9._]+"
        if let regex = try? NSRegularExpression(pattern: mentionPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: allRange)
            for match in matches {
                attr.addAttributes([
                    .foregroundColor: UIColor(named: "accent") ?? .blue,
                    .font: UIFont.systemFont(ofSize: 16, weight: .bold)
                ], range: match.range)
            }
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
    
    private func onEmojiTapped() {
        let isShowing = viewModel?.showEmojiKeybaord == true
        if isShowing {
            threadVM?.delegate?.setTapGesture(enable: true)
        }
        viewModel?.showEmojiKeybaord.toggle()
        btnEmoji.tintColor = viewModel?.showEmojiKeybaord == true ? Color.App.accentUIColor : Color.App.textSecondaryUIColor
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        viewModel?.showEmojiKeybaord = false
    }
}
