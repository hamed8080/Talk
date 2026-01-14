//
//  UIEmojiKeyboardViewFlowLayout.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 1/14/26.
//

import UIKit

class UIEmojiKeyboardViewFlowLayout: UICollectionViewCompositionalLayout {
    init() {
        let sectionEdgeInset: CGFloat = 16
        let numberOfItemsInRow: CGFloat = 8
        let fraction = 1.0 / numberOfItemsInRow
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = .init(leading: .fixed(0), top: .fixed(0), trailing: .fixed(0), bottom: .fixed(0))
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(fraction))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.edgeSpacing = .init(leading: .fixed(0), top: .fixed(0), trailing: .fixed(0), bottom: .fixed(0))
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 4, leading: sectionEdgeInset, bottom: 4, trailing: sectionEdgeInset)
        
        /// Section Header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        
        section.boundarySupplementaryItems = [header]
        
        super.init(section: section)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
