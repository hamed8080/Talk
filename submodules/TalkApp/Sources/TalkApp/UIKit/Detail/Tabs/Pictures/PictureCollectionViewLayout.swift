//
//  PictureCollectionViewLayout.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/26/25.
//

import UIKit
import TalkViewModels

@MainActor
class PictureCollectionViewLayout {
    private let viewModel: DetailTabDownloaderViewModel
    
    init(viewModel: DetailTabDownloaderViewModel) {
        self.viewModel = viewModel
    }
    
    public func createlayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }

            // If there are no items (empty state), return a single full-width item
            if self.viewModel.messagesModels.isEmpty {
                return emptyLayoutSection()
            }
            
            return normalLayoutSection()
        }

        return layout
    }
    
    private func normalLayoutSection() -> NSCollectionLayoutSection {
        let spacing = 8.0
        let mode = UIApplication.shared.windowMode()
        let count = mode.isInSlimMode ? 3 : 5
        let fraction = 1.0 / CGFloat(count)
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(fraction),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(fraction)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = .fixed(spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = .zero
        return section
    }
    
    private func emptyLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .zero
        section.boundarySupplementaryItems = [loadingFooter()]
        return section
    }
    
    private func loadingFooter() -> NSCollectionLayoutBoundarySupplementaryItem {
        let size = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: size,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
    }
}
