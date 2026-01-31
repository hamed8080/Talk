//
//  PictureCell.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/25/25.
//

import UIKit
import SwiftUI
import TalkUI

class PictureCell: UICollectionViewCell {
    private var pictureView = UIImageView()
    public var onContextMenu: ((UIGestureRecognizer) -> Void)?
    public static let identifier = "PICTURE-ROW"
    private weak var model: TabRowModel?
   
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
        model = item
        pictureView.image = item.thumbnailImage
    }
    
    @objc private func openContextMenu(_ sender: UIGestureRecognizer) {
        onContextMenu?(sender)
    }
}

@MainActor
extension PictureCell {
    public func makePictureView() -> UIImageView {
        let pictureView = UIImageView(image: model?.thumbnailImage)
        pictureView.contentMode = .scaleAspectFill
        pictureView.translatesAutoresizingMaskIntoConstraints = false
        pictureView.clipsToBounds = true
        pictureView.layer.cornerRadius = 8
        pictureView.layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
            pictureView.widthAnchor.constraint(equalToConstant: contentView.frame.width),
            pictureView.heightAnchor.constraint(equalToConstant: contentView.frame.height),
        ])
        
        return pictureView
    }
}

extension PictureCell {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.contentView.scaleAnimaiton(isBegan: true, bg: .clear, transformView: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.contentView.scaleAnimaiton(isBegan: false, bg: .clear, transformView: self)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.contentView.scaleAnimaiton(isBegan: false, bg: .clear, transformView: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        self.contentView.scaleAnimaiton(isBegan: false, bg: .clear, transformView: self)
    }
}
