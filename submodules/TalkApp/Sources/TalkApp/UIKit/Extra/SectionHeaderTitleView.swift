//
//  SectionHeaderTitleView.swift
//  Talk
//
//  Created by hamed on 9/10/23.
//

import Foundation
import UIKit
import SwiftUI

class SectionHeaderTitleView: UIView {
    let text: String
    
    init(frame: CGRect, text: String) {
        self.text = text
        super.init(frame: frame)
        
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = Color.App.textSecondaryUIColor
        label.font = UIFont.fCaption
        label.textAlignment = Language.isRTL ? .right : .left
        
        backgroundColor = Color.App.dividerPrimaryUIColor
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
}
