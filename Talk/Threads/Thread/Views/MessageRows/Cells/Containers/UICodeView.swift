//
//  UICodeView.swift
//  Talk
//
//  Created by Hamed Hosseini on 12/20/24.
//

import Foundation
import UIKit
import TalkUI
import SwiftUI
import TalkViewModels

class UICodeView: UIView {
    private var tv: TextMessageView!
    private let bar = UIView()
    private static let codeBG = Color.App.bgSecondaryUIColor?.withAlphaComponent(0.5)
    
    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView(_ isMe: Bool) {
        layer.cornerRadius = 4
        clipsToBounds = true
        
        tv = TextMessageView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        addSubview(tv)
        
        
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        addSubview(bar)
        
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            bar.topAnchor.constraint(equalTo: topAnchor),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor),
            bar.widthAnchor.constraint(equalToConstant: 3),
            
            tv.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: 4),
            tv.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            tv.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            tv.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            tv.widthAnchor.constraint(greaterThanOrEqualToConstant: 128),
        ])
    }
    
    public func setup(_ code: TextOrCode) {
        backgroundColor = code.isCode ? UICodeView.codeBG : UIColor.clear
        let mAtrr = NSMutableAttributedString(string: code.text)
        mAtrr.addDefaultTextColor(UIColor(named: "text_primary") ?? .white)
        mAtrr.addBold()
        mAtrr.addItalic()
        tv.attributedText = mAtrr
        
        bar.setIsHidden(!code.isCode)
    }
}
