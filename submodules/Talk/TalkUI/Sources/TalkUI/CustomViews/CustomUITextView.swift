//
//  CustomUITextView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI
import TalkExtensions
import TalkFont

public struct CustomUITextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    let isEditable: Bool
    let iseUserInteractionEnabled: Bool
    let isSelectable: Bool
    let isScrollingEnabled: Bool
    let font: UIFont
    let textColor: UIColor?
    let size: CGSize

    public init(attributedText: NSAttributedString,
         size: CGSize = .init(width: 72, height: 48),
         isEditable: Bool = false,
         isScrollingEnabled: Bool = false,
         isSelectable: Bool = false,
         iseUserInteractionEnabled: Bool = true,
                font: UIFont = UIFont.normal(.body) ?? UIFont.systemFont(ofSize: 14),
         textColor: UIColor? = UIColor(named: "text")) {
        self.attributedText = attributedText
        self.isEditable = isEditable
        self.iseUserInteractionEnabled = iseUserInteractionEnabled
        self.isScrollingEnabled = isScrollingEnabled
        self.isSelectable = isSelectable
        self.font = font
        self.textColor = textColor
        self.size = size
    }

    public func makeUIView(context: Context) -> some UIView {
        let textView = MyCustomUITextView()
        textView.attributedText = attributedText
        textView.isEditable = isEditable
        textView.isUserInteractionEnabled = iseUserInteractionEnabled
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        textView.isScrollEnabled = isScrollingEnabled
        textView.isSelectable = isSelectable
        textView.frame.origin.y = 0
        textView.invalidateIntrinsicContentSize()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.setContentHuggingPriority(.required, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
//        let size = textView.sizeThatFits(.init(width: 400, height: CGFloat.greatestFiniteMagnitude))
//        textView.heightAnchor.constraint(equalToConstant: size.height + 100).isActive = true
//        textView.widthAnchor.constraint(equalToConstant: size.width).isActive = true
//        textView.invalidateIntrinsicContentSize()
        return textView
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {}
}

public class MyCustomUITextView: UITextView {
    override public var text: String! {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override public var attributedText: NSAttributedString! {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override public var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override public var intrinsicContentSize: CGSize {
        let size = CGSize(width: self.bounds.size.width, height: CGFloat.greatestFiniteMagnitude)
        let newSize = self.sizeThatFits(size)
        return newSize
    }
}
