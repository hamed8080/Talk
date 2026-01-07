//
//  ScrollableTabViewSegmentsHeader.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 1/2/26.
//

import UIKit
import SwiftUI
import TalkUI

final class ScrollableTabViewSegmentsHeader : UITableViewHeaderFooterView {
    private let scrollView = UIScrollView()
    private let scrollContainer = UIView()
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
      
        underlineView.backgroundColor = Color.App.accentUIColor
        underlineView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollContainer.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        scrollContainer.addSubview(segmentedStack)
        scrollContainer.addSubview(underlineView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        scrollView.addSubview(scrollContainer)
        
        contentView.addSubview(scrollView)
    
        // Do NOT add segmentedStackButtonsScrollView to the main view hierarchy here
        underlineLeadingConstraint = underlineView.leadingAnchor.constraint(equalTo: segmentedStack.leadingAnchor)
        underlineLeadingConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            scrollView.heightAnchor.constraint(equalToConstant: 44),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            scrollContainer.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollContainer.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollContainer.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            scrollContainer.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            scrollContainer.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor),
            scrollContainer.heightAnchor.constraint(equalToConstant: 44),

            segmentedStack.topAnchor.constraint(equalTo: scrollContainer.topAnchor),
            segmentedStack.leadingAnchor.constraint(equalTo: scrollContainer.leadingAnchor),
            segmentedStack.heightAnchor.constraint(equalTo: scrollContainer.heightAnchor),

            underlineView.bottomAnchor.constraint(equalTo: scrollContainer.bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 2),
            underlineView.widthAnchor.constraint(equalToConstant: 96)
        ])
        
        if UIDevice.current.userInterfaceIdiom == .phone || traitCollection.horizontalSizeClass == .compact {
            segmentedStack.trailingAnchor.constraint(equalTo: scrollContainer.trailingAnchor).isActive = true
        }
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
        let rect = segmentedStack.convert(button.frame, to: scrollView)

        scrollView.scrollRectToVisible(
            rect.insetBy(dx: -16, dy: 0), // optional padding
            animated: true
        )
    }
}
