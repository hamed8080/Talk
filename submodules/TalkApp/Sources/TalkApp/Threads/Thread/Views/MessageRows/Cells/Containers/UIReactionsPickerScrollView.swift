//
//  UIReactionsPickerScrollView.swift
//  Talk
//
//  Created by hamed on 6/24/24.
//

import Foundation
import UIKit
import Chat
import TalkExtensions
import TalkUI
import TalkViewModels

public struct ExpandORStickerRow: Hashable, Sendable {
    let sticker: Sticker?
    let isMyReaction: Bool
    let expandButton: Bool
}

@MainActor
class UIReactionsPickerScrollView: UIView {
    private let size: CGFloat
    private weak var viewModel: MessageRowViewModel?
    private var cv: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, ExpandORStickerRow>!
    private var isInExapndMode = false
    private var rows: [ExpandORStickerRow] = []
    private var numberOfReactionsInRow: CGFloat { isInExapndMode ? 6 : 5 }
    public var onExpandModeChanged: ((Bool) -> Void)?

    enum Section {
        case main
    }

    init(size: CGFloat) {
        self.size = size
        super.init(frame: .zero)
        configure()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        /*
         We use a fake gesture to prevent the ui being closed by the blur background tap gesture.
         */
        let fakeGetsure = UITapGestureRecognizer(target: self, action: #selector(fakeGesture))
        fakeGetsure.cancelsTouchesInView = false
        addGestureRecognizer(fakeGetsure)

        semanticContentAttribute = .forceLeftToRight
        backgroundColor = .clear
        layer.cornerRadius = size / 2
        layer.masksToBounds = true
    }

    public func setup(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        configureCollectionView()
        setupDataSource()
        applySnapshot(expandMode: false)
    }

    private func configureCollectionView() {
        cv = .init(frame: .zero, collectionViewLayout: createlayout())
        cv.semanticContentAttribute = .forceLeftToRight
        cv.register(UIReactionPickerRowCell.self, forCellWithReuseIdentifier: String(describing: UIReactionPickerRowCell.self))
        cv.delegate = self
        cv.isUserInteractionEnabled = true
        cv.allowsMultipleSelection = false
        cv.allowsSelection = true
        cv.contentInset = .init(top: 0, left: 0, bottom: 0, right: 0)
        cv.showsHorizontalScrollIndicator = false

        cv.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cv)

        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: topAnchor),
            cv.leadingAnchor.constraint(equalTo: leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: trailingAnchor),
            cv.heightAnchor.constraint(equalTo: heightAnchor),
        ])

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let effectView = UIVisualEffectView(effect: blurEffect)
        cv.backgroundView = effectView
    }

    private func createlayout() -> UICollectionViewLayout {
        let sectionInsetLeading: CGFloat = 16
        let sectionInsetTrailing: CGFloat = 4
        let reactionWidth: CGFloat = 320 - (sectionInsetLeading + sectionInsetTrailing)
        let reactionCountWithExpand = numberOfReactionsInRow + (canShowMoreButton() ? 1 : 0)
        let extraItemForSpacing: CGFloat = 1.0
        let trailingMarging: CGFloat = (reactionWidth / (reactionCountWithExpand + extraItemForSpacing)) / (reactionCountWithExpand)
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

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, ExpandORStickerRow>(collectionView: cv) { cv, indexPath, itemIdentifier in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: String(describing: UIReactionPickerRowCell.self), for: indexPath) as? UIReactionPickerRowCell
            let row = self.rows[indexPath.row]
            if let sticker = row.sticker {
                cell?.setModel(sticker)
            } else if row.expandButton {
                cell?.setExpendButton()
            }
            cell?.backgroundColor = row.isMyReaction ? UIColor.gray.withAlphaComponent(0.9) : .clear
            cell?.layer.cornerRadius = row.isMyReaction ? (cell?.frame.height ?? 20) / 2 : 0
            cell?.layer.masksToBounds = row.isMyReaction

            return cell
        }
    }

    private func applySnapshot(expandMode: Bool) {
        self.isInExapndMode = expandMode
        var snapshot = NSDiffableDataSourceSnapshot<Section, ExpandORStickerRow>()
        snapshot.appendSections([.main])

        onExpandModeChanged?(expandMode)
        if isInExapndMode {
            rows.removeAll()
        }

        let stickers = allowedReactions()
            .prefix(prefixCount())
            .compactMap({ ExpandORStickerRow(sticker: $0, isMyReaction: isMyReaction($0), expandButton: false)})
        rows.append(contentsOf: stickers)

        if !isInExapndMode, canShowMoreButton(), !isNumberOfAllowedEqualToNumberOfItemsInARow() {
            let expandButtonRow = ExpandORStickerRow(sticker: nil, isMyReaction: false, expandButton: true)
            rows.append(expandButtonRow)
        }
        snapshot.appendItems(rows)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func isMyReaction(_ sticker: Sticker) -> Bool {
        guard let myReactionStciker = viewModel?.reactionsModel.rows.first(where: {$0.isMyReaction}) else { return false }
        return myReactionStciker.sticker?.rawValue == sticker.rawValue
    }

    @objc private func fakeGesture(_ sender: UIGestureRecognizer) {

    }

    public func expandHeight() -> CGFloat {
        return ceil((CGFloat(allowedReactions().count) / numberOfReactionsInRow)) * size
    }

    private func prefixCount() -> Int {
        if isInExapndMode { return allowedReactions().count }
        // When number of items in first row equal to number of items in a row +1, and +1 means the expand button, so we use a real sticker instead of more button.
        let numberOfItems = isNumberOfAllowedEqualToNumberOfItemsInARow() ? numberOfReactionsInRow + 1 : numberOfReactionsInRow
        return Int(numberOfItems)
    }

    private func allowedReactions() -> [Sticker] {
        if viewModel?.threadVM?.thread.reactionStatus == .enable { return Sticker.allCases.filter({ $0 != .unknown}) }
        return viewModel?.threadVM?.reactionViewModel.allowedReactions ?? []
    }

    private func isNumberOfAllowedEqualToNumberOfItemsInARow() -> Bool {
        CGFloat(allowedReactions().count) == numberOfReactionsInRow + 1
    }

    private func canShowMoreButton() -> Bool {
        allowedReactions().count > Int(numberOfReactionsInRow)
    }
}

extension UIReactionsPickerScrollView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        if let viewModel = viewModel, let messageId = viewModel.message.id, let sticker = row.sticker {
            let myRow = viewModel.reactionsModel.rows.first(where: {$0.isMyReaction})
            viewModel.threadVM?.reactionViewModel.reaction(sticker, messageId: messageId, myReactionId: myRow?.myReactionId, myReactionSticker: myRow?.sticker)
            if let indexPath = viewModel.threadVM?.historyVM.sectionsHolder.sections.indexPath(for: viewModel) {
                viewModel.threadVM?.delegate?.dismissContextMenu(indexPath: indexPath)
            }
        } else if row.expandButton {
            applySnapshot(expandMode: true)
        }
    }
}

final class UIReactionPickerRowCell: UICollectionViewCell {
    private let imageView = UIImageView()

    private let margin: CGFloat = 4

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor , constant: -margin),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: margin),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -margin),
        ])
    }

    private func image(emoji: String, size: CGFloat) -> UIImage {
        let font = UIFont.systemFont(ofSize: size)
        let emojiSize = emoji.size(withAttributes: [.font: font])

        let renderer = UIGraphicsImageRenderer(size: emojiSize)
        let image = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(.init(origin: .zero, size: emojiSize))
            emoji.draw(at: .zero, withAttributes: [.font: font])
        }
        return image
    }

    public func setModel(_ sticker: Sticker) {
        imageView.image = image(emoji: sticker.emoji, size: bounds.width)
    }

    func setExpendButton() {
        imageView.contentMode = .scaleAspectFit
        let colorsConfig = UIImage.SymbolConfiguration(paletteColors: [.white, .gray.withAlphaComponent(0.5)])
        let config = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 14))
        imageView.image = UIImage(systemName: "chevron.down.circle.fill", withConfiguration: config.applying(colorsConfig))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2) {
            self.imageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1.0)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
            UIView.animate(withDuration: 0.2) {
            self.imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }
}
