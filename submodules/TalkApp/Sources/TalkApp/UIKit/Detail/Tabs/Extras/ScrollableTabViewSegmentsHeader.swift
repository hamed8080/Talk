//
//  ScrollableTabViewSegmentsHeader.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 1/2/26.
//

import UIKit
import SwiftUI

final class ScrollableTabViewSegmentsHeader : UITableViewHeaderFooterView {
    private let segmentedStackButtonsScrollView = UIScrollView()
    private let segmentedStack = UIStackView()
    private let underlineView = UIView()
    private var buttons: [UIButton] = []
    public static let identifier: String = "ScrollableTabViewSegmentsHeader"
    
    /// Models
    public var onTapped: ((Int) -> Void)?
    
    /// Constraints
    private var underlineLeadingConstraint: NSLayoutConstraint? = nil
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        segmentedStack.axis = .horizontal
        segmentedStack.distribution = .fill
        segmentedStack.translatesAutoresizingMaskIntoConstraints = false
        segmentedStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        segmentedStackButtonsScrollView.translatesAutoresizingMaskIntoConstraints = false
        segmentedStackButtonsScrollView.showsHorizontalScrollIndicator = false
        segmentedStackButtonsScrollView.showsVerticalScrollIndicator = false
        segmentedStackButtonsScrollView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        segmentedStackButtonsScrollView.addSubview(segmentedStack)
        
        underlineView.backgroundColor = Color.App.accentUIColor
        underlineView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        segmentedStackButtonsScrollView.addSubview(underlineView)
       
        // Do NOT add segmentedStackButtonsScrollView to the main view hierarchy here
        underlineLeadingConstraint = underlineView.leadingAnchor.constraint(equalTo: segmentedStack.leadingAnchor)
        underlineLeadingConstraint?.isActive = true
        
        contentView.addSubview(segmentedStackButtonsScrollView)
    
        NSLayoutConstraint.activate([
            segmentedStackButtonsScrollView.heightAnchor.constraint(equalToConstant: 44),
            segmentedStackButtonsScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            segmentedStackButtonsScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            segmentedStackButtonsScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            segmentedStackButtonsScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            segmentedStack.topAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.topAnchor),
            segmentedStack.bottomAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.bottomAnchor),
            segmentedStack.leadingAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.leadingAnchor),
            segmentedStack.trailingAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.trailingAnchor),
            segmentedStack.heightAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.heightAnchor),
            
            underlineView.bottomAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 2),
            underlineView.widthAnchor.constraint(equalToConstant: 96)
        ])
    }
    
    public func setButtons(buttonTitles: [String]) {
        for (index, title) in buttonTitles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.tag = index
            button.titleLabel?.font = UIFont.normal(.body)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            button.setTitleColor(.secondaryLabel, for: .normal)
            buttons.append(button)
            
            segmentedStack.addArrangedSubview(button)
            
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 96),
                button.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }
    
    @objc private func tabTapped(_ sender: UIButton) {
        let index = sender.tag
        onTapped?(index)
    }
    
    public func updateTabSelection(animated: Bool, selectedIndex: Int) {
        updateSelectedIndexButton(selectedIndex)
        updateUnderline(selectedIndex)
        scrollToSelectedIndex(selectedIndex)
        if animated {
            UIView.animate(withDuration: 0.15) {
                self.layoutIfNeeded()
            }
        } else {
            self.layoutIfNeeded()
        }
    }
    
    private func updateSelectedIndexButton(_ selectedIndex: Int) {
        for (i, button) in buttons.enumerated() {
            button.setTitleColor(i == selectedIndex ? .label : .secondaryLabel, for: .normal)
        }
    }
    
    private func updateUnderline(_ selectedIndex: Int) {
        let underlinePosition = CGFloat(selectedIndex) * 96
        underlineLeadingConstraint?.constant = underlinePosition
    }
    
    private func scrollToSelectedIndex(_ selectedIndex: Int) {
        guard selectedIndex < buttons.count else { return }
        
        let button = buttons[selectedIndex]
        
        // Convert button frame into scrollView's content space
        let rect = segmentedStack.convert(button.frame, to: segmentedStackButtonsScrollView)

        segmentedStackButtonsScrollView.scrollRectToVisible(
            rect.insetBy(dx: -16, dy: 0), // optional padding
            animated: true
        )
    }
}
