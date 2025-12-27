//
//  NothingFoundCell.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 10/29/25.
//

import UIKit
import TalkModels

class NothingFoundCell: UITableViewCell {
    public static let identifier = "NOTHING-FOUND-ROW"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        /// Background color once is selected or tapped
        selectionStyle = .none
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        let view = NothingFoundView()
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0),
            view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        ])
    }
}

class NothingFoundCollectionViewCell: UICollectionViewCell {
    public static let identifier = "NOTHING-FOUND-COLLECTION-VIEW-ROW"

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        let view = NothingFoundView()
        view.backgroundColor = .red
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        ])
    }
}
