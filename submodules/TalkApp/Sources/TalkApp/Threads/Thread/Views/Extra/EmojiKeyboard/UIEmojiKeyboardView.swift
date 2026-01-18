//
//  UIEmojiKeyboardView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 1/14/26.
//

import Foundation
import UIKit
import TalkModels

class UIEmojiKeyboardView: UIView {
    private var cv: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<EmojisSection, String>!
    public var onEmojiSelect: ((String) -> Void)?
    private var sections: [EmojisSection] = []
    
    init() {
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        isUserInteractionEnabled = true
        translatesAutoresizingMaskIntoConstraints = false
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        cv = UICollectionView(frame: .zero, collectionViewLayout: UIEmojiKeyboardViewFlowLayout())
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.semanticContentAttribute = .forceLeftToRight
        cv.register(UIEmojiRowCell.self, forCellWithReuseIdentifier: UIEmojiRowCell.identifier)
        cv.register(UIEmojiSectionHeaderLabelView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UIEmojiSectionHeaderLabelView.identifier)
        cv.delegate = self
        cv.isUserInteractionEnabled = true
        cv.allowsMultipleSelection = false
        cv.allowsSelection = true
        cv.contentInset = .init(top: 0, left: 0, bottom: 0, right: 0)
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.backgroundColor = nil
        addSubview(cv)

        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: topAnchor),
            cv.leadingAnchor.constraint(equalTo: leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: trailingAnchor),
            cv.heightAnchor.constraint(equalTo: heightAnchor),
        ])
        setupDataSource()
        applySnapshot()
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<EmojisSection, String>(collectionView: cv) { [weak self] cv, indexPath, itemIdentifier in
            guard let self = self,
                  let cell = cv.dequeueReusableCell(withReuseIdentifier: String(describing: UIEmojiRowCell.self), for: indexPath) as? UIEmojiRowCell
            else { return nil }
            
            let row = self.sections[indexPath.section].items[indexPath.row]
            cell.label.text = row
            return cell
        }
        
        dataSource.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) in
            guard let self = self else { return nil }
            
            if kind == UICollectionView.elementKindSectionHeader {
                let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: UIEmojiSectionHeaderLabelView.identifier, for: indexPath) as! UIEmojiSectionHeaderLabelView
                let section = self.sections[indexPath.section]
                reusableView.label.text = section.title.uppercased()
                return reusableView
            }
            return nil
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
    
    func initSections() {
        if !sections.isEmpty { return }
        sections = EmojiRange.allCases
        applySnapshot()
    }
}

extension UIEmojiKeyboardView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = sections[indexPath.section].items[indexPath.row]
        onEmojiSelect?(row)
    }
}
