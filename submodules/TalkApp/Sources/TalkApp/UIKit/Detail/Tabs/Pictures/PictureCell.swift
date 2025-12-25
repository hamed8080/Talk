//
//  PictureCell.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/25/25.
//

import UIKit
import SwiftUI

class PictureCell: UICollectionViewCell {
    private var pictureView = UIImageView()
    public var onContextMenu: ((UIGestureRecognizer) -> Void)?
   
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
        
        /// Title of the conversation.
        pictureView.translatesAutoresizingMaskIntoConstraints = false
        pictureView.accessibilityIdentifier = "PictureCell.pictureView"
        pictureView.contentMode = .scaleAspectFill
        pictureView.clipsToBounds = true
        pictureView.layer.cornerRadius = 8
        pictureView.layer.masksToBounds = true
        contentView.addSubview(pictureView)
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(openContextMenu))
        longGesture.minimumPressDuration = 0.3
        addGestureRecognizer(longGesture)
        
        NSLayoutConstraint.activate([
            pictureView.topAnchor.constraint(equalTo: contentView.topAnchor),
            pictureView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pictureView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pictureView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    public func setItem(_ item: TabRowModel) {
        pictureView.image = item.thumbnailImage
    }
    
    @objc private func openContextMenu(_ sender: UIGestureRecognizer) {
        onContextMenu?(sender)
    }
}
