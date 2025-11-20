//
//  AutoDismissSwipeAction.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 11/20/25.
//

import UIKit
import SwiftUI
import TalkViewModels

@MainActor
class AutoDismissSwipeAction {
    /// Views
    private weak var cell: UITableViewCell?
    private let swipeReplyImageView = PaddingUIImageView()
    
    /// id to pass in callback
    private var id: Int?
    
    /// Constraints
    private var edgeConstraint: NSLayoutConstraint?
    private var swipeReplyLeadingConstaraint: NSLayoutConstraint?
    
    /// Swipe variables
    private var translation: CGFloat = 0
    private var beginPoint: CGPoint = .zero
    private var gesture: UIPanGestureRecognizer?
    public var onSwipe: ((Int) -> Void)?
    private var isEnabled = true
    
    /// Computed propeties
    private var contentView: UIView { cell?.contentView ?? .init() }
    private var isMe: Bool { cell is MyselfMessageCell }
    private var isRTL: Bool { Language.isRTL }
    
    public init(cell: UITableViewCell) {
        self.cell = cell
    }
    
    public func setupCell(cell: UITableViewCell?, id: Int?, edgeConstraint: NSLayoutConstraint?) {
        self.id = id
        self.edgeConstraint = edgeConstraint
        attachOrDetachSwipeReplyImage()
        addSwipeGestureRecognizer()
    }
    
    private func addSwipeGestureRecognizer() {
        gesture = UIPanGestureRecognizer(target: self, action: #selector(onSwipeGesture))
        gesture?.maximumNumberOfTouches = 1
        gesture?.minimumNumberOfTouches = 1
        gesture?.delegate = cell
        if let gesture = gesture {
            contentView.addGestureRecognizer(gesture)
        }
    }
    
    public func setEnabled(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
    
    private func attachOrDetachSwipeReplyImage() {
        if swipeReplyImageView.superview != nil { return }
        
        swipeReplyImageView.contentMode = .scaleAspectFit
        swipeReplyImageView.tintColor = Color.App.whiteUIColor
        swipeReplyImageView.backgroundColor = Color.App.accentUIColor
        swipeReplyImageView.layer.cornerRadius = ConstantSizes.imageViewSwipeWidth / 2
        swipeReplyImageView.layer.masksToBounds = true
        swipeReplyImageView.translatesAutoresizingMaskIntoConstraints = false
        swipeReplyImageView.accessibilityIdentifier = "swipeReplyImageViewMessageBaseCell"
        let image = UIImage(systemName: "arrowshape.turn.up.left") ?? .init()
        swipeReplyImageView.set(image: image, inset: .init(horizontal: 6, vertical: 6))
        contentView.addSubview(swipeReplyImageView)
        
        NSLayoutConstraint.activate([
            swipeReplyImageView.widthAnchor.constraint(equalToConstant: ConstantSizes.imageViewSwipeWidth),
            swipeReplyImageView.heightAnchor.constraint(equalToConstant: ConstantSizes.imageViewSwipeWidth),
            swipeReplyImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        swipeReplyLeadingConstaraint = swipeReplyImageView.trailingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0)
        swipeReplyLeadingConstaraint?.isActive = true
    }
    
    @objc private func onSwipeGesture(_ sender: UIPanGestureRecognizer) {
        let translationX = sender.translation(in: contentView).x
        let translationY = abs(sender.translation(in: contentView).y)
        
        switch sender.state {
        case .began:
            beginPoint = sender.location(in: contentView)
        case .changed:
            let isPopGesture = contentView.frame.width - beginPoint.x < ConstantSizes.maximumEdgeDistanceToConfirm
          
            let isScrollingUPOrDown = translationY > abs(translationX)
            if !isScrollingUPOrDown, isEnabled, !isPopGesture, isMe && translationX < 0 || !isMe && translationX < 0 {
                edgeConstraint?.constant = -translationX
                let absoluteTranslation = abs(translationX)
                self.translation = absoluteTranslation
                swipeReplyLeadingConstaraint?.constant = min(absoluteTranslation, ConstantSizes.minimumSwipeToConfirm)
            }
        case .ended:
            if self.translation > ConstantSizes.minimumSwipeToConfirm {
                onConfirmSwipe()
            }
            resetSwipe()
        case .cancelled, .failed:
            resetSwipe()
        default:
            resetSwipe()
        }
    }
    
    private func resetSwipe() {
        resetEdgeConstant()
        resetTranslation()
        resetReplyLeadingConstant()
    }
    
    private func resetEdgeConstant() {
        
        let rightMessage = (isRTL && isMe) || (!isRTL && !isMe)
        let defaultConstant = ConstantSizes.beforeContainerLeading
        edgeConstraint?.constant = rightMessage ? defaultConstant : -defaultConstant
    }
    
    private func resetTranslation() {
        translation = 0
    }
    
    private func resetReplyLeadingConstant() {
        swipeReplyLeadingConstaraint?.constant = 0
    }
    
    private func onConfirmSwipe() {
        onSwipe?(id ?? -1)
    }
}
