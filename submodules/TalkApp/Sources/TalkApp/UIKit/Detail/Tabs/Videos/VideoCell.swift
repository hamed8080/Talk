//
//  VideoCell.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/25/25.
//

import UIKit
import SwiftUI

class VideoCell: UITableViewCell {
    weak var viewModel: ThreadDetailViewModel?
    private var rowModel: TabRowModel?
    private let rowDetail = TabDetailsTextView()
    private let progressButton = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                      iconTint: Color.App.whiteUIColor,
                                                      bgColor: Color.App.accentUIColor,
                                                      margin: 2
    )
    private let separator = TableViewControllerDevider()
    public var onContextMenu: ((UIGestureRecognizer) -> Void)?
    public static let identifier = "VIDEO-ROW"
   
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func configureView() {
        /// Background color once is selected or tapped
        selectionStyle = .none
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        /// Progress button.
        progressButton.accessibilityIdentifier = "VideoCell.progressButton"
        progressButton.translatesAutoresizingMaskIntoConstraints = false
        progressButton.isUserInteractionEnabled = false
        contentView.addSubview(progressButton)
        
        rowDetail.translatesAutoresizingMaskIntoConstraints = false
        rowDetail.accessibilityIdentifier = "VideoCell.rowDetail"
        contentView.addSubview(rowDetail)
        
        contentView.addSubview(separator)
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(openContextMenu))
        longGesture.minimumPressDuration = 0.3
        addGestureRecognizer(longGesture)
        
        NSLayoutConstraint.activate([
            progressButton.widthAnchor.constraint(equalToConstant: ConstantSizes.tabProgressButtonItemWidth),
            progressButton.heightAnchor.constraint(equalToConstant: ConstantSizes.tabProgressButtonItemHeight),
            progressButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
        
            rowDetail.centerYAnchor.constraint(equalTo: progressButton.centerYAnchor),
            rowDetail.leadingAnchor.constraint(equalTo: progressButton.trailingAnchor, constant: 8),
            rowDetail.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            separator.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -ConstantSizes.tableViewSeparatorLeading),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: ConstantSizes.tableViewSeparatorHeight),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
        ])
    }
    
    public func setItem(_ item: TabRowModel) {
        rowModel = item
        rowDetail.configure(with: item)
        updateProgress(item)
    }
    
    public func updateProgress(_ item: TabRowModel) {
        let icon = item.stateIcon
        let isCompleted = item.state.state == .completed
        
        /// Hide it before calling aniamte method to prevent rotation back to 0.0 postion.
        if isCompleted {
            progressButton.setProgressVisibility(visible: false)
        }
        
        progressButton.animate(to: isCompleted ? 0.0 : item.state.progress, systemIconName: icon)
    }
    
    @objc private func openContextMenu(_ sender: UIGestureRecognizer) {
        onContextMenu?(sender)
    }
}
