//
//  UIEmojiKeyboardViewFlowLayout.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 1/14/26.
//

import UIKit
import TalkViewModels

class UIEmojiKeyboardViewFlowLayout: UICollectionViewCompositionalLayout {
    init() {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(ConstantSizes.emojiKeyboardCellWidth),
                                              heightDimension: .absolute(ConstantSizes.emojiKeyboardCellHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = .init(leading: .fixed(0), top: .fixed(0), trailing: .fixed(0), bottom: .fixed(0))

        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(ConstantSizes.emojiKeyboardGroupWidth),
                                               heightDimension: .absolute(ConstantSizes.emojiKeyboardGroupHeight))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.edgeSpacing = .init(leading: .fixed(0), top: .fixed(ConstantSizes.emojiKeyboardHeaderHeight), trailing: .fixed(0), bottom: .fixed(0))
        
        /// Section Header
        let headerSize = NSCollectionLayoutSize(widthDimension: .estimated(120),
                                                heightDimension: .absolute(ConstantSizes.emojiKeyboardHeaderHeight))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .topLeading)
        header.extendsBoundary = false
        header.pinToVisibleBounds = true
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: ConstantSizes.emojiKeyboardSectionSpaceTrailing)
        section.boundarySupplementaryItems = [header]
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        
        super.init(section: section, configuration: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
