//
//  CustomizeReactionsViewController.swift
//  Talk
//
//  Created by hamed on 7/31/24.
//

import Foundation
import UIKit
import TalkUI
import TalkModels
import TalkViewModels
import ChatDTO
import SwiftUI
import ChatModels
import Chat

@MainActor
final class CustomizeReactionsViewController: UIViewController {
    // Views
    private var cv: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<CustomizeReactionSection, Item>!
    private let btnSubmit = SubmitBottomButtonUIView(text: "General.done")
    private var toolbarView: CustomizeReactionsToolbar!

    // Models
    private let size: CGFloat = 36
    public weak var viewModel: ThreadViewModel?
    private var sections: [CustomizeReactionSection] = []
    private var numberOfReactionsInRow: CGFloat = 5
    private let allStickers = Sticker.allCases

    // Constarints
    private var heightSubmitConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    public func configure() {
        view.backgroundColor = Color.App.bgPrimaryUIColor
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        initializeSections()
        configureCollectionView()
        setupDataSource()
        applySnapshot()
        configureBtnSumbit()
        configureToolbar()
        setConstraints()
        disableSubmitButtonIfNeeded()
    }

    private func configureBtnSumbit() {
        btnSubmit.translatesAutoresizingMaskIntoConstraints = false
        btnSubmit.accessibilityIdentifier = "btnSubmitCustomizeReactionsViewController"
        btnSubmit.action = { [weak self] in
            self?.submitTapped()
        }
        view.addSubview(btnSubmit)
    }

    private func configureToolbar() {
        toolbarView = CustomizeReactionsToolbar(viewModel: viewModel)
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbarView)
    }

    private func setConstraints() {
        heightSubmitConstraint = btnSubmit.heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            cv.heightAnchor.constraint(equalTo: view.heightAnchor),

            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            btnSubmit.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            btnSubmit.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            heightSubmitConstraint,
            btnSubmit.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bottom: CGFloat = view.safeAreaInsets.bottom
        heightSubmitConstraint.constant = 64 + bottom
        cv.contentInset = .init(top: 48, left: 0, bottom: 64 + bottom, right: 0)
    }

    private func initializeSections() {
        let selecteds = allowedStickers()
        sections.append(.init(type: .selected, rows: selecteds.compactMap({.init(sticker: $0, selected: true)})))

        let unselecteds = allStickers.filter{ !selecteds.contains($0) && $0 != .unknown}
        sections.append(.init(type: .unselected, rows: unselecteds.compactMap({.init(sticker: $0, selected: false)})))
    }

    private func configureCollectionView() {
        cv = .init(frame: .zero, collectionViewLayout: createlayout())
        cv.semanticContentAttribute = .forceLeftToRight
        cv.register(CustomizeReactionUICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: CustomizeReactionUICollectionViewCell.self))
        cv.register(CustomizeReactionSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CustomizeReactionSectionHeader.reuseIdentifier)
        cv.register(BackgroundLabelView.self, forSupplementaryViewOfKind: "backgroundLabel", withReuseIdentifier: BackgroundLabelView.reuseIdentifier)
        cv.delegate = self
        cv.isUserInteractionEnabled = true
        cv.allowsMultipleSelection = false
        cv.allowsSelection = true
        cv.contentInset = .init(top: 0, left: 0, bottom: 0, right: 0)
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = Color.App.bgPrimaryUIColor
        cv.contentInset = .init(top: 48, left: 0, bottom: 64, right: 0)

        cv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cv)
    }

    private func createlayout() -> UICollectionViewLayout {
        let fraction = 1.0 / numberOfReactionsInRow
        let cellHeight: CGFloat = view.frame.width / numberOfReactionsInRow

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction),
                                              heightDimension: .absolute(cellHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(cellHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        //
        // Add supplementary view for "no items" case
        let hasAnyItemAtSectionSelected = sections.first?.rows.count ?? 0 > 0
        let backgroundSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(!hasAnyItemAtSectionSelected ? 48 : 0))
        let background = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: backgroundSize,
            elementKind: "backgroundLabel",
            alignment: .bottom
        )

        // Add header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header, background]

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<CustomizeReactionSection, Item>(collectionView: cv) { cv, indexPath, itemIdentifier in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: CustomizeReactionUICollectionViewCell.identifier,
                                              for: indexPath) as? CustomizeReactionUICollectionViewCell
            let row = self.sections[indexPath.section].rows[indexPath.row]
            cell?.setModel(row, type: self.sections[indexPath.section].type)
            return cell
        }

        // Supplementary View Provider for Headers
        dataSource.supplementaryViewProvider = { (collectionView, kind, indexPath) in
            if kind == UICollectionView.elementKindSectionHeader {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: CustomizeReactionSectionHeader.reuseIdentifier,
                                                                             for: indexPath) as? CustomizeReactionSectionHeader
                let section = self.sections[indexPath.section]
                header?.setText(section.type == .selected ? "CustomizeReactions.selectedReactions".bundleLocalized() : "CustomizeReactions.emojis".bundleLocalized())
                return header
            } else if kind == "backgroundLabel" {
                let labelView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BackgroundLabelView.reuseIdentifier, for: indexPath) as! BackgroundLabelView
                let section = self.sections[indexPath.section]
                labelView.label.text = section.rows.isEmpty ? "CustomizeReactions.nothingSelected".bundleLocalized() : ""
                labelView.isHidden = !section.rows.isEmpty
                return labelView
            }
            return nil
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<CustomizeReactionSection, Item>()
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(section.rows, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func reapplySnapshot(item: Item, toSection: CustomizeSectionType) {
        var currentSnapShot = dataSource.snapshot()
        currentSnapShot.deleteItems([item])
        if let toSection = currentSnapShot.sectionIdentifiers.first(where: {$0.type == toSection}) {
            currentSnapShot.appendItems([item], toSection: toSection)
        }
        dataSource.apply(currentSnapShot, animatingDifferences: true)
        updateSupplementaryViewVisibility()

        var currentSnapshot = dataSource.snapshot()
        currentSnapshot.reloadItems([item])
        dataSource.apply(currentSnapshot)

        // To show or hide nothing has selected and update it's size
        if sections.first?.rows.isEmpty == true {
            updateLayout()
        }
    }

    private func updateLayout() {
        cv.collectionViewLayout = createlayout()
        cv.collectionViewLayout.invalidateLayout()
    }

    private func updateSupplementaryViewVisibility() {
        for (index, section) in sections.enumerated() {
            let shouldShow = section.rows.isEmpty
            let indexPath = IndexPath(item: 0, section: index)
            if let view = cv.supplementaryView(forElementKind: "backgroundLabel", at: indexPath) as? BackgroundLabelView {
                view.isHidden = !shouldShow
            }
        }
    }

    private func allowedStickers() -> [Sticker] {
        return viewModel?.reactionViewModel.allowedReactions ?? []
    }

    private func submitTapped() {
        let selecteds = sections.filter({ $0.type == .selected }).flatMap({$0.rows}).compactMap({$0.sticker})
        let req = ConversationCustomizeReactionsRequest(conversationId: viewModel?.id ?? -1, reactionStatus: .custom, allowedReactions: selecteds)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.reaction.customizeReactions(req)
        }
        navigationController?.popViewController(animated: true)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let isInSlimMode = AppState.shared.windowMode.isInSlimMode
        let isInHalfSplit = AppState.shared.windowMode == .ipadHalfSplitView
        if !isInSlimMode, !isInHalfSplit, numberOfReactionsInRow != 12 {
            numberOfReactionsInRow = 12
            updateLayout()
        } else if isInSlimMode || isInHalfSplit, numberOfReactionsInRow != 5 {
            numberOfReactionsInRow = 5
            updateLayout()
        }
    }

    private func isValidToChange() -> Bool {
        let selectedCount = sections.first?.rows.count ?? 0
        let unSelectedCount = sections.last?.rows.count ?? 0
        let isBetween = selectedCount >= 1 && unSelectedCount >= 1
        return isBetween
    }

    private func disableSubmitButtonIfNeeded() {
        let isValidToChange = isValidToChange()
        UIView.animate(withDuration: 0.2) {
            self.btnSubmit.isUserInteractionEnabled = isValidToChange
            self.btnSubmit.alpha = isValidToChange ? 1.0 : 0.4
        }
    }
}

extension CustomizeReactionsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        let isSelected = sections[indexPath.section].type == .selected
        if !canMove(isSelected: isSelected) { return }

        // Determine source and destination sections
        let fromSection = isSelected ? CustomizeSectionType.selected : CustomizeSectionType.unselected
        let toSection = isSelected ? CustomizeSectionType.unselected : CustomizeSectionType.selected
        moveSticker(row, from: fromSection, to: toSection, isSelected: !isSelected)
        reapplySnapshot(item: row, toSection: toSection)

        disableSubmitButtonIfNeeded()
    }

    private func moveSticker(_ item: Item, from oldSectionType: CustomizeSectionType, to newSectionType: CustomizeSectionType, isSelected: Bool) {

        // Find and update the old section
        if let oldSectionIndex = sections.firstIndex(where: { $0.type == oldSectionType }) {
            sections[oldSectionIndex].rows.removeAll { $0.sticker.rawValue == item.sticker.rawValue }
        }

        // Find and update the new section
        if let toSectionIndex = sections.firstIndex(where: { $0.type == newSectionType }) {
            self.sections[toSectionIndex].rows.append(item)
        }
    }

    private func canMove(isSelected: Bool) -> Bool {
        let selectedsCount = sections.first?.rows.count ?? 0
        let unselectedsCount = sections.last?.rows.count ?? 0

        let canMoveToSelected = !isSelected && unselectedsCount > 1
        let canMoveToUNSelected = isSelected && selectedsCount > 0

        return canMoveToSelected || canMoveToUNSelected
    }
}
