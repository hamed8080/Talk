//
//  ThreadBottomToolbar.swift
//  Talk
//
//  Created by hamed on 3/24/24.
//

import Foundation
import UIKit
import TalkViewModels
import Combine
import TalkUI
import TalkModels

@MainActor
public final class ThreadBottomToolbar: UIStackView {
    private weak var viewModel: ThreadViewModel?
    private let mainSendButtons: MainSendButtons
    private let audioRecordingContainerView: AudioRecordingContainerView
    private let pickerButtons: PickerButtonsView
    private let attachmentFilesTableView: AttachmentFilesTableView
    private let replyPrivatelyPlaceholderView: ReplyPrivatelyMessagePlaceholderView
    private let replyPlaceholderView: ReplyMessagePlaceholderView
    private let forwardPlaceholderView: ForwardMessagePlaceholderView
    private let editMessagePlaceholderView: EditMessagePlaceholderView
    private let mentionTableView: MentionTableView
    public let selectionView: SelectionView
    private let muteBarView: MuteChannelBarView
    private let closedBarView: ClosedBarView
    private let emojiKeyboardView: UIEmojiKeyboardView
    public var onUpdateHeight: (@Sendable (CGFloat) -> Void)?

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        self.mainSendButtons = MainSendButtons(viewModel: viewModel)
        self.audioRecordingContainerView = AudioRecordingContainerView(viewModel: viewModel)
        self.pickerButtons = PickerButtonsView(viewModel: viewModel?.sendContainerViewModel, threadVM: viewModel)
        self.attachmentFilesTableView = AttachmentFilesTableView(viewModel: viewModel)
        self.replyPlaceholderView = ReplyMessagePlaceholderView(viewModel: viewModel)
        self.replyPrivatelyPlaceholderView = ReplyPrivatelyMessagePlaceholderView(viewModel: viewModel)
        self.forwardPlaceholderView = ForwardMessagePlaceholderView(viewModel: viewModel)
        self.editMessagePlaceholderView = EditMessagePlaceholderView(viewModel: viewModel)
        self.selectionView = SelectionView(viewModel: viewModel)
        self.muteBarView = MuteChannelBarView(viewModel: viewModel)
        self.closedBarView = ClosedBarView(viewModel: viewModel)
        self.mentionTableView = MentionTableView(viewModel: viewModel)
        self.emojiKeyboardView = UIEmojiKeyboardView()
        super.init(frame: .zero)
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        editMessagePlaceholderView.superViewStack = self
        editMessagePlaceholderView.registerObservers()
        
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        axis = .vertical
        alignment = .fill
        spacing = 0
        isLayoutMarginsRelativeArrangement = true
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.layer.masksToBounds = true
        effectView.layer.cornerRadius = 0
        effectView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        effectView.accessibilityIdentifier = "effectViewThreadBottomToolbar"
        addSubview(effectView)
        sendSubviewToBack(effectView)

        // addArrangedSubview(replyPrivatelyPlaceholderView)
        attachmentFilesTableView.stack = self
        forwardPlaceholderView.stack = self
        forwardPlaceholderView.set() // Show forward placeholder on open the thread
        replyPrivatelyPlaceholderView.stack = self
        replyPrivatelyPlaceholderView.set()
        if viewModel?.thread.closed == true {
            addArrangedSubview(closedBarView)
        } else if viewModel?.sendContainerViewModel.canShowMuteChannelBar() == true {
            addArrangedSubview(muteBarView)
        } else {
            addArrangedSubview(mainSendButtons)
        }
        addArrangedSubview(emojiKeyboardView)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func showMainButtons(_ show: Bool, withRemoveAnimaiton: Bool = true) {
        if !show {
            removeMainSendButtonWithAnimation(withRemoveAnimation: withRemoveAnimaiton)
        } else if mainSendButtons.superview == nil {
            if show, viewModel?.sendContainerViewModel.canShowMuteChannelBar() == true {
                animateToShowChannelMuteBar()
            } else {
                animateToShowMainSendButton()
            }
        }
    }

    public func showPickerButtons(_ show: Bool) {
        showPicker(show: show)
        viewModel?.scrollVM.disableExcessiveLoading()
    }

    public func showSelectionBar(_ show: Bool) {
        selectionView.show(show: show, stack: self)
    }

    public func updateSelectionBar() {
        selectionView.update(stack: self)
    }

    public func updateMentionList() {
        mentionTableView.updateMentionList(stack: self)
    }

    private func showPicker(show: Bool) {
        pickerButtons.show(show, stack: self)
    }

    public func updateHeightWithDelay() {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                onUpdateHeight?(frame.height)
            }
        }
    }
    
    public func openReplyMode(_ message: HistoryMessageType?) {
        replyPlaceholderView.set(stack: self)
    }

    public func focusOnTextView(focus: Bool) {
        mainSendButtons.focusOnTextView(focus: focus)
    }

    public func showForwardPlaceholder(show: Bool) {
        forwardPlaceholderView.set()
    }

    public func showReplyPrivatelyPlaceholder(show: Bool) {
        replyPrivatelyPlaceholderView.set()
    }

    public func openRecording(_ show: Bool) {
        viewModel?.attachmentsViewModel.clear()
        showMainButtons(!show, withRemoveAnimaiton: false)
        audioRecordingContainerView.show(show, stack: self) // Reset to show RecordingView again
    }

    public func onConversationClosed() {
        for view in arrangedSubviews {
            view.removeFromSuperview()
        }
        addArrangedSubview(closedBarView)
        closedBarView.closed()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateHeightWithDelay()
    }

    public func muteChanged() {
        muteBarView.set()
    }
    
    private func animateToShowChannelMuteBar() {
        UIView.animate(withDuration: 0.2) {
            self.mainSendButtons.removeFromSuperview()
            self.muteBarView.set()
        }
    }
    
    private func animateToShowMainSendButton() {
        mainSendButtons.alpha = 0.0
        insertArrangedSubview(mainSendButtons, at: 0)
        UIView.animate(withDuration: 0.2) {
            self.mainSendButtons.alpha = 1.0
        }
    }
    
    private func removeMainSendButtonWithAnimation(withRemoveAnimation: Bool) {
        // withRemoveAnimation prevents having two views in the stack and leads to a really tall view and a bad animation.
        mainSendButtons.removeFromSuperViewWithAnimation(withAimation: withRemoveAnimation)
        mainSendButtons.removeFromSuperview()
    }
}

class UIEmojiKeyboardView: UIView {
    private var cv: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<EmojisSection, String>!
    public var onEmojiSelect: ((String) -> Void)?
    
    struct EmojisSection: Hashable {
        var title: String
        var items: [String]
    }
    
    private var sections: [EmojisSection] = EmojiRange.allCases.compactMap{ .init(title: $0.key, items: EmojiRange(value: $0.value).emojies()) }
    
    init() {
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        cv = UICollectionView(frame: .zero, collectionViewLayout: createlayout())
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.semanticContentAttribute = .forceLeftToRight
        cv.register(UIEmojiRowCell.self, forCellWithReuseIdentifier: UIEmojiRowCell.identifier)
        cv.delegate = self
        cv.isUserInteractionEnabled = true
        cv.allowsMultipleSelection = false
        cv.allowsSelection = true
        cv.contentInset = .init(top: 0, left: 0, bottom: 0, right: 0)
        cv.showsHorizontalScrollIndicator = false
        cv.isScrollEnabled = false
        addSubview(cv)

        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: topAnchor),
            cv.leadingAnchor.constraint(equalTo: leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: trailingAnchor),
            cv.heightAnchor.constraint(equalToConstant: 320),
        ])
        setupDataSource()
        applySnapshot()
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<EmojisSection, String>(collectionView: cv) { cv, indexPath, itemIdentifier in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: String(describing: UIEmojiRowCell.self), for: indexPath) as? UIEmojiRowCell
            let row = self.sections[indexPath.section].items[indexPath.row]
            cell?.label.text = row
            return cell
        }
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<EmojisSection, String>()
        for section in sections {
            snapshot.appendSections([section])
            snapshot.appendItems(section.items, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension UIEmojiKeyboardView {
    private func createlayout() -> UICollectionViewLayout {
        let sectionInsetLeading: CGFloat = 16
        let sectionInsetTrailing: CGFloat = 4
        let numberOfReactionsInRow: CGFloat = 8
        let reactionWidth: CGFloat = 320 - (sectionInsetLeading + sectionInsetTrailing)
        let reactionCountWithExpand = numberOfReactionsInRow
        let extraItemForSpacing: CGFloat = 1.0
        let trailingMarging: CGFloat = 8
        let fraction = 1.0 / (reactionCountWithExpand + extraItemForSpacing)

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = .init(leading: .fixed(0), top: .fixed(0), trailing: .fixed(trailingMarging), bottom: .fixed(0))

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(fraction))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.edgeSpacing = .init(leading: .fixed(0), top: .fixed(0), trailing: .fixed(0), bottom: .fixed(8))

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 4, leading: sectionInsetLeading, bottom: 4, trailing: sectionInsetTrailing)

        let layout = UICollectionViewCompositionalLayout(section: section)

        return layout
    }
}

extension UIEmojiKeyboardView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = sections[indexPath.section].items[indexPath.row]
        onEmojiSelect?(row)
    }
}

final class UIEmojiRowCell: UICollectionViewCell {
    static let identifier: String = "UIEmojiRowCell"
    let label = UILabel()
    private let margin: CGFloat = 4
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        backgroundColor = .clear
        layer.cornerRadius = contentView.frame.height / 2.0
        layer.masksToBounds = false
        
        label.contentMode = .scaleAspectFit
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor , constant: -margin),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: margin),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -margin),
        ])
    }
}
