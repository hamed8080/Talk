//
//  TableViewControllerDevider.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 11/12/25.
//

import UIKit
import TalkViewModels

class TableViewControllerDevider: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.black.withAlphaComponent( traitCollection.userInterfaceStyle == .dark ? 0.3 : 0.1)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ConstantSizes.tableViewSeparatorHeight),
        ])
    }
}
