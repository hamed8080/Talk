//
//  FooterReactionsCountView.swift
//  Talk
//
//  Created by hamed on 8/22/23.
//

import TalkExtensions
import TalkViewModels
import SwiftUI
import Chat
import TalkUI
import TalkModels

final class FooterReactionsCountView: UIStackView {
    private weak var viewModel: MessageRowViewModel?
    private let scrollView = UIScrollView()
    private let reactionStack = UIStackView()
    private var scrollViewMinWidthConstraint: NSLayoutConstraint?

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        spacing = ConstantSizes.footerReactionsCountViewStackSpacing
        alignment = .fill
        distribution = .fill
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        accessibilityIdentifier = "stackReactionCountScrollView"

        reactionStack.translatesAutoresizingMaskIntoConstraints = false
        reactionStack.axis = .horizontal
        reactionStack.spacing = ConstantSizes.footerReactionsCountViewStackSpacing
        reactionStack.alignment = .fill
        reactionStack.distribution = .fillProportionally
        reactionStack.semanticContentAttribute = Language.isRTL || isMe ? .forceRightToLeft : .forceLeftToRight
        reactionStack.accessibilityIdentifier = "reactionStackcrollView"

        /// Add four items into the reactionStack and just change the visibility with setHidden method.
        for _ in 0..<ConstantSizes.footerReactionsCountViewMaxReactionsToShow {
            reactionStack.addArrangedSubview(ReactionCountRowView(frame: .zero, isMe: isMe))
        }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.accessibilityIdentifier = "FooterReactionsCountViewScrollView"
        scrollView.addSubview(reactionStack)
        
        addArrangedSubview(MoreReactionButtonRow(frame: .zero, isMe: isMe))
        addArrangedSubview(scrollView)
        
        scrollViewMinWidthConstraint = scrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)
        scrollViewMinWidthConstraint?.identifier = "FooterReactionsCountViewWidthConstriant"
        scrollViewMinWidthConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            reactionStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            reactionStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            reactionStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            reactionStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: ConstantSizes.footerReactionsCountViewScrollViewHeight),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let rows = rows(viewModel: viewModel)
        
        updateWidthConstraint(rows)
        
        /// Show rows only if rows.count == inde
        /// Max of rows.count could be 4.
        /// Index is stable inside reactionStack and it is 0...4
        reactionStack.arrangedSubviews.enumerated().forEach { index, view in
            if index < rows.count, let rowView = view as? ReactionCountRowView {
                rowView.setIsHidden(false)
                rowView.setValue(row: rows[index])
                rowView.backgroundColor = viewModel.calMessage.isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
                rowView.viewModel = viewModel
            } else {
                view.setIsHidden(true)
            }
        }
        
        /// Hide or show More than 4 reactions button
        if viewModel.reactionsModel.rows.count > ConstantSizes.footerReactionsCountViewMaxReactionsToShow, let moreButton = arrangedSubviews[0] as? MoreReactionButtonRow {
            moreButton.setIsHidden(false)
            moreButton.row = .moreReactionRow
            moreButton.viewModel = viewModel
        } else if let moreButton = arrangedSubviews[0] as? MoreReactionButtonRow {
            moreButton.setIsHidden(true)
        }
    }
    
    public func reactionDeleted(_ reaction: Reaction) {
        updateReactionsWithAnimation(viewModel: viewModel)
    }
    
    public func reactionAdded(_ reaction: Reaction) {
        updateReactionsWithAnimation(viewModel: viewModel)
    }
    
    public func reactionReplaced(_ reaction: Reaction) {
        updateReactionsWithAnimation(viewModel: viewModel)
    }
    
    private func updateReactionsWithAnimation(viewModel: MessageRowViewModel?) {
        if let viewModel = viewModel {
            let rows = rows(viewModel: viewModel)
            updateWidthConstraint(rows)
            UIView.animate(withDuration: 0.20) {
                self.set(viewModel)
            }
        }
    }
    
    private func updateWidthConstraint(_ rows: [ReactionRowsCalculated.Row]) {
        /// It will prevent the time label be truncated by reactions view.
        /// We use cached version of isInSlimMode instead of the AppState.shared.windowMode.isInSlimMode which is a computed property
        let isSlimMode = AppState.isInSlimMode
        if rows.count > 3 && isSlimMode {
            /// + ConstantSizes.messageReactionRowViewTotalWidth for size of the more button
            let totalSize = rows.compactMap{$0.width}.reduce(0, {$0 + $1}) + (ConstantSizes.messageReactionRowViewTotalWidth / 2)
            scrollViewMinWidthConstraint?.constant = min(ConstantSizes.footerReactionsCountViewScrollViewMaxWidth, totalSize)
        } else {
            scrollViewMinWidthConstraint?.constant = rows.compactMap{$0.width}.reduce(0, {$0 + 4 + $1})
        }
        scrollViewMinWidthConstraint?.isActive = !rows.isEmpty
    }
    
    private func rows(viewModel: MessageRowViewModel) -> [ReactionRowsCalculated.Row] {
        return viewModel.reactionsModel.rows.count > ConstantSizes.footerReactionsCountViewMaxReactionsToShow ? Array(viewModel.reactionsModel.rows.prefix(4)) : viewModel.reactionsModel.rows
    }
}
