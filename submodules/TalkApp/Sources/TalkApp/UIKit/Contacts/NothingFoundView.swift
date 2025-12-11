//
//  NothingFoundView.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import SwiftUI
import TalkUI

class NothingFoundView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        label.font = UIFont.normal(.body)
        label.textColor = Color.App.textSecondaryUIColor
        label.textAlignment = .center
        label.text = "General.noResult".bundleLocalized()
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
        ])
    }
}
